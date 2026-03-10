# Packer / Proxmox

Build configuration for Proxmox VM templates using Packer.

## Prerequisites

1. Prepare or adjust variable files:

- `proxmox/t620/microos/variables.pkr.hcl`
- `proxmox/t620/variables_secrets.pkr.hcl` - based on the `.example` file, when using 1password, op inject command can be used: `op inject -i variables_secrets.pkr.hcl.example -o variables_secrets.pkr.hcl`

2. Ensure the Proxmox API token is generated and has permissions for VM creation and storage operations.

## Build commands

Force option is used to delete old templates. Run from [packer/](.) directory:

```sh
packer init config.pkr.hcl
packer validate -var-file='proxmox/t620/microos/variables.pkr.hcl' -var-file='proxmox/t620/variables_secrets.pkr.hcl' proxmox/t620/microos/proxmox-iso-microos.pkr.hcl
packer build -force -var-file='proxmox/t620/microos/variables.pkr.hcl' -var-file='proxmox/t620/variables_secrets.pkr.hcl' proxmox/t620/microos/proxmox-iso-microos.pkr.hcl
```

## Current template assumptions (MicroOS)

- `root` SSH login with password is enabled so Packer can complete provisioning.
- `qemu-guest-agent` is required for IP detection.
- `cloud-init` is installed in the base image for use in cloned VMs.

## Known issues

1. Upload issue is caused by proxmox-iso packer plugin integration, this command can start working after a few retries.

```sh
--> proxmox-iso.linux: Post "https://192.168.1.20:8006/api2/json/nodes/t620/storage/local/upload": write tcp 192.168.1.101:65122->192.168.1.20:8006: use of closed network connection
```

2. When multiple host network interfaces are active (e.g., Wi-Fi and Ethernet), AutoYaST may bind to the wrong one and use a different network than the Proxmox node. Disable Wi-Fi during deployment.
