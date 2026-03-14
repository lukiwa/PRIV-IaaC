variable "proxmox_host" {
  type = string
}

variable "proxmox_ssh_user" {
  type = string
}

variable "proxmox_ssh_password" {
  type      = string
  sensitive = true
}

variable "media_macaddr" {
  type = string
}

variable "media_public_key" {
  type = string
}

variable "media_password" {
  type      = string
  sensitive = true
}
