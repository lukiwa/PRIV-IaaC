variable "t620_proxmox_host" {
  type = string
}

variable "t620_proxmox_ssh_user" {
  type = string
}

variable "t620_proxmox_ssh_password" {
  type      = string
  sensitive = true
}

variable "t620_microos_media_macaddr" {
  type = string
}

variable "t620_microos_media_public_key" {
  type = string
}

variable "t620_microos_media_password" {
  type      = string
  sensitive = true
}
