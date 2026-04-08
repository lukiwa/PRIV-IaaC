terraform {
  required_version = ">= 1.14.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

locals {
  snippet_name        = var.cloud_init_snippet_name != "" ? var.cloud_init_snippet_name : "${var.vm_name}-vendor"
  snippet_remote_path = "/var/lib/vz/snippets/${local.snippet_name}.yml"

  vendor_data_upload_enabled = var.cloud_init_enabled && var.cloud_init_vendor_data_path != ""

  external_disk_path    = trimspace(var.external_disk_path)
  external_disk_enabled = local.external_disk_path != ""
}

resource "terraform_data" "cloud_init_upload" {
  count = local.vendor_data_upload_enabled ? 1 : 0

  triggers_replace = [filemd5(var.cloud_init_vendor_data_path)]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "file" {
    source      = var.cloud_init_vendor_data_path
    destination = "/tmp/${local.snippet_name}.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/vz/snippets",
      "cp /tmp/${local.snippet_name}.yml ${local.snippet_remote_path}",
    ]
  }
}

resource "proxmox_vm_qemu" "this" {
  name         = var.vm_name
  description  = var.vm_description
  vmid         = var.vmid
  force_create = var.force_create
  target_node  = var.target_node

  depends_on = [terraform_data.cloud_init_upload]

  agent     = 1
  skip_ipv6 = true

  clone = var.clone_template

  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
  }

  memory  = var.memory
  balloon = var.balloon

  network {
    id      = 0
    bridge  = var.network_bridge
    model   = "virtio"
    macaddr = var.network_macaddr != "" ? var.network_macaddr : null
  }

  disk {
    storage = var.disk_storage
    slot    = "virtio0"
    type    = "disk"
    size    = var.disk_size
  }

  dynamic "disk" {
    for_each = var.cloud_init_enabled ? [1] : []
    content {
      storage = var.disk_storage
      slot    = "ide2"
      type    = "cloudinit"
    }
  }

  os_type   = var.cloud_init_enabled ? "cloud-init" : null
  ipconfig0 = var.cloud_init_enabled ? var.ipconfig0 : null

  cicustom = (
    local.vendor_data_upload_enabled
    ? "vendor=${var.cloud_init_storage}:snippets/${local.snippet_name}.yml"
    : null
  )

  ciupgrade  = var.cloud_init_enabled ? var.ciupgrade : null
  ciuser     = var.cloud_init_enabled && var.ciuser != "" ? var.ciuser : null
  cipassword = var.cloud_init_enabled && var.cipassword != "" ? var.cipassword : null
  sshkeys    = var.cloud_init_enabled && var.sshkeys != "" ? var.sshkeys : null

  # telmate/proxmox returns disks in arbitrary order and injects startup_shutdown
  # defaults — both cause a perpetual diff on every plan. Known provider bug.
  lifecycle {
    ignore_changes = [disk, startup_shutdown]
  }
}

resource "terraform_data" "attach_external_disk" {
  count = local.external_disk_enabled ? 1 : 0

  triggers_replace = [
    proxmox_vm_qemu.this.vmid,
    local.external_disk_path,
    timestamp(),
  ]

  depends_on = [proxmox_vm_qemu.this]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "qm set ${proxmox_vm_qemu.this.vmid} --virtio1 '${local.external_disk_path},backup=0' && qm reboot ${proxmox_vm_qemu.this.vmid}",
    ]
  }
}
