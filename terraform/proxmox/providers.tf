terraform {
  required_version = ">= 1.14.5"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.proxmox_api_url)) > 0
    error_message = "proxmox_api_url must be set (e.g. https://<host>:8006/api2/json)."
  }
}

variable "proxmox_api_user" {
  type = string

  validation {
    condition     = length(trimspace(var.proxmox_api_user)) > 0
    error_message = "proxmox_api_user must be set (e.g. root@pam)."
  }
}

variable "proxmox_api_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(trimspace(var.proxmox_api_password)) > 0
    error_message = "proxmox_api_password must be set (non-empty)."
  }
}

provider "proxmox" {
  pm_api_url  = var.proxmox_api_url
  pm_user     = var.proxmox_api_user
  pm_password = var.proxmox_api_password

  pm_tls_insecure             = true
  pm_minimum_permission_check = false
}
