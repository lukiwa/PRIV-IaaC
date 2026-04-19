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
  template_filename = basename(var.template_url)
  ostemplate        = "${var.template_storage}:vztmpl/${local.template_filename}"
}

resource "terraform_data" "template_download" {
  triggers_replace = [var.template_url]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "wget -q -nc -P /var/lib/vz/template/cache/ '${var.template_url}'",
    ]
  }
}

resource "proxmox_lxc" "this" {
  hostname    = var.hostname
  description = var.description
  vmid        = var.vmid
  target_node = var.target_node

  ostemplate   = local.ostemplate
  unprivileged = var.unprivileged
  force        = var.force_create

  password        = var.password != "" ? var.password : null
  ssh_public_keys = var.sshkeys != "" ? var.sshkeys : null

  cores  = var.cpu_cores
  memory = var.memory
  swap   = var.swap

  onboot = var.start_at_node_boot
  start  = true

  rootfs {
    storage = var.disk_storage
    size    = var.disk_size
  }

  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = var.ip
    gw     = var.ip != "dhcp" && var.gateway != "" ? var.gateway : null
    hwaddr = var.network_macaddr != "" ? var.network_macaddr : null
  }

  depends_on = [terraform_data.template_download]

  features {
    nesting = var.features_nesting
  }

  # telmate/proxmox fills in computed network attributes on read, producing
  # a perpetual diff on every plan. Known provider quirk (same as disk in VM module).
  lifecycle {
    ignore_changes = [network]
  }
}

# Passes /dev/net/tun into the container so Podman can create tun interfaces.
# Required for UniFi OS Server (and any other workload using Podman networking).
# Only works with privileged containers (unprivileged = false).
# https://github.com/kam821/Unifi-OS-Server-on-LXC-Proxmox
resource "terraform_data" "tun_passthrough" {
  count = var.tun_passthrough ? 1 : 0

  triggers_replace = [proxmox_lxc.this.vmid]

  depends_on = [proxmox_lxc.this]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "pct stop ${proxmox_lxc.this.vmid}",
      "grep -qF 'lxc.cgroup2.devices.allow: c 10:200' /etc/pve/lxc/${proxmox_lxc.this.vmid}.conf || echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${proxmox_lxc.this.vmid}.conf",
      "grep -qF 'lxc.mount.entry: /dev/net/tun' /etc/pve/lxc/${proxmox_lxc.this.vmid}.conf || echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${proxmox_lxc.this.vmid}.conf",
      "pct start ${proxmox_lxc.this.vmid}",
    ]
  }
}
