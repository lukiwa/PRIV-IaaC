locals {
  external_disk_id      = trimspace(var.external_disk_id)
  external_disk_enabled = local.external_disk_id != ""
  external_disk_path    = "/dev/disk/by-id/${local.external_disk_id}"
}

resource "terraform_data" "cloud_init_upload" {
  triggers_replace = [filemd5("${path.module}/cloud-init/vendor-data.yml")]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "file" {
    source      = "${path.module}/cloud-init/vendor-data.yml"
    destination = "/opt/microos-media-vendor.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/vz/snippets",
      "cp /opt/microos-media-vendor.yml /var/lib/vz/snippets/microos-media-vendor.yml",
    ]
  }
}

resource "proxmox_vm_qemu" "microos-media" {
  name         = "microos-media"
  description  = "MicroOS host for media containers"
  vmid         = 1001
  force_create = true
  target_node  = "t620"

  depends_on = [
    terraform_data.cloud_init_upload,
  ]

  agent     = 1
  skip_ipv6 = true

  clone = "microos.20260315-2129"
  cpu {
    cores   = 4
    sockets = 1
  }
  memory = 5024

  network {
    id      = 0
    bridge  = "vmbr1"
    model   = "virtio"
    macaddr = var.media_macaddr
  }

  disk {
    storage = "local-zfs"
    slot    = "virtio0"
    type    = "disk"
    size    = "60G"
  }

  disk {
    storage = "local-zfs"
    slot    = "ide2"
    type    = "cloudinit"
  }

  os_type    = "cloud-init"
  ipconfig0  = "ip=dhcp"
  cicustom   = "vendor=local:snippets/microos-media-vendor.yml"
  ciupgrade  = true
  ciuser     = "mediauser"
  cipassword = var.media_password
  sshkeys    = var.media_public_key
}

resource "terraform_data" "attach_external_disk" {
  count = local.external_disk_enabled ? 1 : 0

  triggers_replace = [
    proxmox_vm_qemu.microos-media.vmid,
    local.external_disk_path,
  ]

  depends_on = [
    proxmox_vm_qemu.microos-media,
  ]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "qm set ${proxmox_vm_qemu.microos-media.vmid} --virtio1 \"${local.external_disk_path},backup=0\" && qm reboot ${proxmox_vm_qemu.microos-media.vmid}",
    ]
  }
}
