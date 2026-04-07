output "vmid" {
  description = "Proxmox VM ID."
  value       = proxmox_vm_qemu.this.vmid
}

output "vm_name" {
  value = proxmox_vm_qemu.this.name
}

output "default_ipv4_address" {
  description = "First IPv4 reported by the QEMU guest agent."
  value       = proxmox_vm_qemu.this.default_ipv4_address
}
