ballooning_minimum = "0"
boot_wait          = "15s"
cores              = "4"
cpu_type           = "host"
disable_kvm        = false

disks = {
  cache_mode   = "none"
  disk_size    = "20G"
  format       = "raw"
  type         = "virtio"
  storage_pool = "local-zfs"
  io_thread    = true
  discard      = true
}

insecure_skip_tls_verify = true
memory                   = "4096"

network_adapters = {
  bridge      = "vmbr0" # requires management interface to connect to http with autoyast
  model       = "virtio"
  firewall    = false
  mac_address = ""
  vlan_tag    = ""
}

proxmox_node            = "t620"
qemu_agent              = true
scsi_controller         = "virtio-scsi-single"
cloud_init              = true
cloud_init_storage_pool = "local-zfs"
cloud_init_disk_type    = "scsi"
sockets                 = "1"
ssh_password            = "password"
ssh_username            = "root"
