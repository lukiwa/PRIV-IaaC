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

  hostname    = "alpine-lxc-caddy"
  description = "Alpine Caddy container"
  vmid        = 102
  target_node = include.env.locals.target_node

  template_url     = "http://download.proxmox.com/images/system/alpine-3.23-default_20260116_amd64.tar.xz"
  template_storage = "local"

  unprivileged = true

  cpu_cores = 2
  memory    = 1536
  swap      = 2048

  disk_storage = "local-zfs"
  disk_size    = "5G"

  network_bridge  = "vmbr1"
  network_macaddr = include.lxc_secrets.locals.macaddr
  ip              = "dhcp"

  password = include.lxc_secrets.locals.password
  sshkeys  = include.lxc_secrets.locals.public_key

  features_nesting   = false
  tun_passthrough    = false
  start_at_node_boot = true
  force_create       = false
}
