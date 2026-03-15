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

variable "external_disk_id" {
  type        = string
  default     = ""
  description = "Optional /dev/disk/by-id identifier to passthrough as virtio1. Leave empty to disable passthrough."
}
