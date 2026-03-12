terraform {
  required_version = ">= 1.14.5"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc03"
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = ""
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true
  pm_minimum_permission_check = false
}
