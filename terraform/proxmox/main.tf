module "t620_microos_media" {
  source = "./t620/microos-media"

  proxmox_host         = var.t620_proxmox_host
  proxmox_ssh_user     = var.t620_proxmox_ssh_user
  proxmox_ssh_password = var.t620_proxmox_ssh_password

  media_macaddr    = var.t620_microos_media_macaddr
  media_public_key = var.t620_microos_media_public_key
  media_password   = var.t620_microos_media_password
}
