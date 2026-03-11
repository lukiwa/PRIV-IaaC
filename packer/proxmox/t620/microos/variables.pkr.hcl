boot_command        = "<esc><enter><wait> linux textmode=1 autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/autoinst.xml <wait5><enter>"
http_directory      = "files/http"
cloud-init_path     = "files/cloud-init"
cloud-init_cfg_name = "99-packer.cfg"
boot_iso = {
  iso_storage_pool = "local"
  iso_url          = "https://download.opensuse.org/tumbleweed/iso/openSUSE-MicroOS-DVD-x86_64-Current.iso"
  iso_checksum     = "none" # rolling release distro
  unmount          = true
}
vm_id                  = 1000
ssh_timeout            = "40m"
ssh_handshake_attempts = 500
task_timeout           = "1h"
template               = "microos"
