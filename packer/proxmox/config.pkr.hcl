packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source  = "github.com/hashicorp/qemu"
    }
    proxmox = {
      version = "= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
