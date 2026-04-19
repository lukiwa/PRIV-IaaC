output "vmid" {
  description = "Proxmox container ID."
  value       = proxmox_lxc.this.vmid
}

output "hostname" {
  description = "Container hostname."
  value       = proxmox_lxc.this.hostname
}
