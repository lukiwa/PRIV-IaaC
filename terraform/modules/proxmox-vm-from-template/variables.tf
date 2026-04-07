variable "proxmox_host" {
  type        = string
  description = "Proxmox host address for SSH provisioners."
}

variable "proxmox_ssh_user" {
  type        = string
  description = "SSH username for Proxmox host provisioners."
}

variable "proxmox_ssh_password" {
  type      = string
  sensitive = true
}

variable "vm_name" {
  type = string
}

variable "vm_description" {
  type    = string
  default = ""
}

variable "vmid" {
  type        = number
  description = "Proxmox VM ID. Must be unique within the cluster."
}

variable "target_node" {
  type = string
}

variable "clone_template" {
  type        = string
  description = "Proxmox template name to clone (packer-built, qcow2-imported, etc.)."
}

variable "force_create" {
  type    = bool
  default = true
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "cpu_sockets" {
  type    = number
  default = 1
}

variable "memory" {
  type        = number
  default     = 2048
  description = "RAM in megabytes."
}

variable "disk_size" {
  type    = string
  default = "20G"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]$", var.disk_size))
    error_message = "disk_size must be a positive integer followed by K, M, G or T (e.g. '45G')."
  }
}

variable "disk_storage" {
  type        = string
  default     = "local-zfs"
  description = "Proxmox storage pool for the primary disk and cloud-init ISO."
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_macaddr" {
  type    = string
  default = ""
}

variable "cloud_init_enabled" {
  type    = bool
  default = true
}

variable "cloud_init_vendor_data_path" {
  type        = string
  default     = ""
  description = "Local path to vendor-data.yml. Uploaded to Proxmox snippets and referenced via cicustom when non-empty."
}

variable "cloud_init_snippet_name" {
  type        = string
  default     = ""
  description = "Snippet name on Proxmox (no path, no extension). Defaults to '<vm_name>-vendor'."
}

variable "cloud_init_storage" {
  type        = string
  default     = "local"
  description = "Proxmox storage pool hosting the snippets/ directory."
}

variable "ipconfig0" {
  type    = string
  default = "ip=dhcp"
}

variable "ciuser" {
  type    = string
  default = ""
}

variable "cipassword" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sshkeys" {
  type    = string
  default = ""
}

variable "ciupgrade" {
  type    = bool
  default = true
}

variable "external_disk_path" {
  type        = string
  default     = ""
  description = "Full path to the disk to passthrough as virtio1 (e.g. '/dev/disk/by-id/ata-...', '/dev/disk/by-uuid/...'). Leave empty to skip."
}
