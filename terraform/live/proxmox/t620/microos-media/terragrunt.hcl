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

include "vm_secrets" {
  path   = "${get_terragrunt_dir()}/secrets.hcl"
  expose = true
}

terraform {
  source = "${get_repo_root()}/terraform/modules/proxmox-vm-from-template"
}

inputs = {
  proxmox_host         = include.node_secrets.locals.proxmox_host
  proxmox_ssh_user     = include.env.locals.proxmox_ssh_user
  proxmox_ssh_password = include.node_secrets.locals.proxmox_ssh_password

  vm_name        = "microos-media"
  vm_description = "MicroOS host for media containers"
  vmid           = 1001
  target_node    = include.env.locals.target_node
  clone_template = "microos.20260315-2129"

  start_at_node_boot = true

  cpu_cores   = 4
  cpu_sockets = 1
  memory      = 5120
  balloon     = 2048

  disk_size    = "45G"
  disk_storage = "local-zfs"

  network_bridge  = "vmbr1"
  network_macaddr = include.vm_secrets.locals.macaddr

  cloud_init_enabled          = true
  cloud_init_vendor_data_path = "${get_terragrunt_dir()}/cloud-init/vendor-data.yml"
  cloud_init_snippet_name     = "microos-media-vendor"
  cloud_init_storage          = "local"

  ipconfig0  = "ip=dhcp"
  ciuser     = "mediauser"
  cipassword = include.vm_secrets.locals.password
  sshkeys    = include.vm_secrets.locals.public_key
  ciupgrade  = true

  external_disk_path = include.vm_secrets.locals.disk_path
  force_create       = false
}
