# Packer Template to create an Microos on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "boot_command" {
  type    = string
  default = ""
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "password"
}

variable "ssh_timeout" {
  type    = string
  default = "10000s"
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "ssh_handshake_attempts" {
  type    = number
  default = 200
}
variable "template" {
  type    = string
  default = ""
}

variable "cloud-init_path" {
  type    = string
  default = ""
}

variable "cloud_init" {
  type    = bool
  default = false
}

variable "cloud_init_storage_pool" {
  type    = string
  default = "local-zfs"
}

variable "cloud-init_cfg_name" {
  type    = string
  default = ""
}

variable "cloud_init_disk_type" {
  type    = string
  default = ""
}


variable "http_directory" {
  type    = string
  default = ""
}

variable "proxmox_node" {
  type    = string
  default = ""
}

variable "disks" {
  type = object({
    cache_mode   = string
    disk_size    = string
    format       = string
    storage_pool = string
    type         = string
    io_thread    = bool
    discard      = bool
  })
  default = {
    cache_mode   = "none"
    disk_size    = "50G"
    format       = "qcow2"
    storage_pool = "local"
    type         = "virtio"
    io_thread    = true
    discard      = true
  }
}

variable "boot_wait" {
  type    = string
  default = "10s"
}

variable "cores" {
  type    = string
  default = "1"
}

variable "sockets" {
  type    = string
  default = "1"
}

variable "os" {
  type    = string
  default = "l26"
}

variable "disable_kvm" {
  type    = bool
  default = false
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "network_adapters" {
  type = object({
    bridge      = string
    model       = string
    firewall    = bool
    mac_address = string
    vlan_tag    = string
  })
  default = {
    bridge      = "vmbr1"
    model       = "virtio"
    firewall    = false
    mac_address = ""
    vlan_tag    = ""
  }
}

variable "ballooning_minimum" {
  type    = string
  default = "0"
}

variable "boot_iso" {
  type = object({
    iso_storage_pool = string
    iso_url          = string
    iso_checksum     = string
    unmount          = bool
  })
  default = {
    iso_storage_pool = "local"
    iso_url          = ""
    iso_checksum     = ""
    unmount          = true
  }
}

variable "vm_id" {
  type    = number
  default = 1000
}

variable "insecure_skip_tls_verify" {
  type    = bool
  default = true
}

variable "task_timeout" {
  type    = string
  default = "15m"
}

variable "scsi_controller" {
  type    = string
  default = "virtio-scsi-single"
}

variable "qemu_agent" {
  type    = bool
  default = true
}

variable "efi_storage_pool" {
  type    = string
  default = "local"
}

variable "pre_enrolled_keys" {
  type    = bool
  default = false
}

variable "efi_type" {
  type    = string
  default = "4m"
}

variable "bios" {
  type    = string
  default = "seabios"
}

variable "machine" {
  type    = string
  default = "pc"
}

variable "tags" {
  type    = string
  default = "bios;template"
}

locals {
  packer_timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
}

source "proxmox-iso" "linux" {
  ballooning_minimum = "${var.ballooning_minimum}"
  boot_command       = ["${var.boot_command}"]
  boot_wait          = "${var.boot_wait}"
  bios               = "${var.bios}"
  cores              = "${var.cores}"
  cpu_type           = "${var.cpu_type}"
  disable_kvm        = "${var.disable_kvm}"
  disks {
    cache_mode   = "${var.disks.cache_mode}"
    disk_size    = "${var.disks.disk_size}"
    format       = "${var.disks.format}"
    storage_pool = "${var.disks.storage_pool}"
    type         = "${var.disks.type}"
    io_thread    = "${var.disks.io_thread}"
    discard      = "${var.disks.discard}"
  }
  http_directory           = "${path.root}/${var.http_directory}"
  insecure_skip_tls_verify = "${var.insecure_skip_tls_verify}"
  boot_iso {
    iso_url      = "${var.boot_iso.iso_url}"
    iso_checksum = "${var.boot_iso.iso_checksum}"
    #iso_download_pve  = true
    #iso_file          = "local:iso/openSUSE-MicroOS-DVD-x86_64-Current.iso"
    iso_storage_pool = "${var.boot_iso.iso_storage_pool}"
    unmount          = var.boot_iso.unmount
  }
  machine = "${var.machine}"
  memory  = "${var.memory}"
  network_adapters {
    bridge      = "${var.network_adapters.bridge}"
    model       = "${var.network_adapters.model}"
    firewall    = "${var.network_adapters.firewall}"
    mac_address = "${var.network_adapters.mac_address}"
    vlan_tag    = "${var.network_adapters.vlan_tag}"
  }
  node                    = "${var.proxmox_node}"
  vm_id                   = "${var.vm_id}"
  os                      = "${var.os}"
  proxmox_url             = "${var.proxmox_api_url}"
  qemu_agent              = "${var.qemu_agent}"
  cloud_init              = "${var.cloud_init}"
  cloud_init_storage_pool = "${var.cloud_init_storage_pool}"
  cloud_init_disk_type    = "${var.cloud_init_disk_type}"
  scsi_controller         = "${var.scsi_controller}"
  sockets                 = "${var.sockets}"
  ssh_port                = "${var.ssh_port}"
  ssh_username            = "${var.ssh_username}"
  ssh_password            = "${var.ssh_password}"
  ssh_timeout             = "${var.ssh_timeout}"
  ssh_handshake_attempts  = "${var.ssh_handshake_attempts}"
  tags                    = "${var.tags}"
  task_timeout            = "${var.task_timeout}"
  template_name           = "${var.template}.${local.packer_timestamp}"
  token                   = "${var.proxmox_api_token_secret}"
  username                = "${var.proxmox_api_token_id}"
}

build {
  sources = ["source.proxmox-iso.linux"]

  provisioner "file" {
    destination  = "/etc/cloud/${var.cloud-init_cfg_name}"
    source       = "${path.root}/${var.cloud-init_path}/${var.cloud-init_cfg_name}"
    pause_before = "3m" # wait for autoyast2 stage 2 to finish
  }

}
