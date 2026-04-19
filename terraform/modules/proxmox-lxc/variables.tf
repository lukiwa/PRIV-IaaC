
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

variable "target_node" {
  type        = string
  description = "Proxmox node name where the container will be created."
}

variable "hostname" {
  type        = string
  description = "Container hostname."
}

variable "description" {
  type    = string
  default = ""
}

variable "vmid" {
  type        = number
  description = "Proxmox container ID. Must be unique within the cluster."
}


variable "template_storage" {
  type        = string
  default     = "local"
  description = "Proxmox storage pool where the template will be downloaded and stored."
}

variable "template_url" {
  type        = string
  description = "Direct download URL for the LXC template (e.g. 'http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst'). Downloaded to /var/lib/vz/template/cache/ if not already present."
}

variable "force_create" {
  type    = bool
  default = false
}

variable "unprivileged" {
  type        = bool
  default     = true
  description = "Run the container in unprivileged mode."
}

variable "cpu_cores" {
  type    = number
  default = 1
}

variable "memory" {
  type        = number
  default     = 512
  description = "RAM in megabytes."
}

variable "swap" {
  type        = number
  default     = 512
  description = "Swap in megabytes. 0 disables swap."
}

variable "disk_storage" {
  type        = string
  default     = "local-zfs"
  description = "Proxmox storage pool for the root filesystem."
}

variable "disk_size" {
  type    = string
  default = "8G"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]$", var.disk_size))
    error_message = "disk_size must be a positive integer followed by K, M, G or T (e.g. '8G')."
  }
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_macaddr" {
  type    = string
  default = ""
}

variable "ip" {
  type        = string
  default     = "dhcp"
  description = "IPv4 address in CIDR notation (e.g. '192.168.1.10/24') or 'dhcp'."
}

variable "gateway" {
  type        = string
  default     = ""
  description = "IPv4 default gateway. Leave empty when ip = 'dhcp'."
}

variable "password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Root password inside the container. Leave empty to disable password auth."
}

variable "sshkeys" {
  type        = string
  default     = ""
  description = "Newline-separated authorized SSH public keys for root."
}

variable "tun_passthrough" {
  type        = bool
  default     = false
  description = "Pass /dev/net/tun into the container (required for Podman networking in UniFi OS Server). Only works with privileged containers."
}

variable "start_at_node_boot" {
  type        = bool
  default     = false
  description = "Start the container automatically when the Proxmox node boots."
}

variable "features_nesting" {
  type        = bool
  default     = false
  description = "Enable nesting. Required for systemd 257+ and Docker-in-LXC."
}
