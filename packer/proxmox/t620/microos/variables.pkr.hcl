ballooning_minimum  = "0"
boot_command        = "<esc><enter><wait> linux textmode=1 autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/autoinst.xml <wait5><enter>"
boot_wait           = "15s"
http_directory      = "files/http"
cloud-init_path     = "files/cloud-init"
cloud-init_cfg_name = "99-packer.cfg"
cores               = "4"
cpu_type            = "host"
disable_kvm         = false
disks = {
  cache_mode   = "none"
  disk_size    = "25G"
  format       = "raw"
  type         = "virtio"
  storage_pool = "local-zfs"
  io_thread    = true
  discard      = true
}
insecure_skip_tls_verify = true
boot_iso = {
  iso_storage_pool = "local"
  iso_url          = "https://download.opensuse.org/tumbleweed/iso/openSUSE-MicroOS-DVD-x86_64-Current.iso"
  iso_checksum     = "none" # rolling release distro
  unmount          = true
}
memory = "4096"
network_adapters = {
  bridge      = "vmbr0" # requires management interface to connect to http with autoyast
  model       = "virtio"
  firewall    = false
  mac_address = ""
  vlan_tag    = ""
}
proxmox_node           = "t620"
vm_id                  = 1000
qemu_agent             = true
scsi_controller        = "virtio-scsi-single"
sockets                = "1"
ssh_password           = "password"
ssh_username           = "root"
ssh_timeout            = "40m"
ssh_handshake_attempts = 500
task_timeout           = "1h"
template               = "microos"
