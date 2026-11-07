include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

include "node_secrets" {
  path   = find_in_parent_folders("secrets.hcl")
  expose = true
}

include "lxc_secrets" {
  path   = "${get_terragrunt_dir()}/secrets.hcl"
  expose = true
}

terraform {
  source = "${get_repo_root()}/terraform/modules/proxmox-lxc"
}

inputs = {
  proxmox_host         = include.node_secrets.locals.proxmox_host
  proxmox_ssh_user     = include.env.locals.proxmox_ssh_user
  proxmox_ssh_password = include.node_secrets.locals.proxmox_ssh_password

  hostname    = "debian-lxc-homebridge"
  description = "Debian 13 Homebridge container"
  vmid        = 103
  target_node = include.env.locals.target_node

  template_url     = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  template_storage = "local"

  unprivileged = true

  cpu_cores = 2
  memory    = 1024
  swap      = 512

  disk_storage = "local-zfs"
  disk_size    = "8G"

  network_bridge  = "vmbr1"
  network_macaddr = include.lxc_secrets.locals.macaddr
  ip              = "dhcp"

  password = include.lxc_secrets.locals.password
  sshkeys  = include.lxc_secrets.locals.public_key

  features_nesting   = true
  tun_passthrough    = false
  start_at_node_boot = true
  force_create       = false
}
