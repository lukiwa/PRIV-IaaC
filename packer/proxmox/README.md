# Packer / Proxmox

Build configuration for Proxmox VM templates using Packer.

## Prerequisites

1. Prepare or adjust variable files:

- `proxmox/t620/variables.pkr.hcl` (global for all distros on this host)
- `proxmox/t620/<DISTRO>/variables.pkr.hcl` (Distro-specific)
- `proxmox/t620/secrets.pkr.hcl` - populate from 1Password: `cd packer && ./setup.sh`

1. Ensure the Proxmox API token is generated and has permissions for VM creation and storage operations.

## Build commands

Force option is used to delete old templates. Run from [packer/proxmox/](.) directory:

```sh
packer init config.pkr.hcl
packer validate \
  -var-file='t620/variables.pkr.hcl' \
  -var-file='t620/<DISTRO>/variables.pkr.hcl' \
  -var-file='t620/secrets.pkr.hcl' \
  t620/<DISTRO>/proxmox-iso.pkr.hcl
packer build -force \
  -var-file='t620/variables.pkr.hcl' \
  -var-file='t620/<DISTRO>/variables.pkr.hcl' \
  -var-file='t620/secrets.pkr.hcl' \
  t620/<DISTRO>/proxmox-iso.pkr.hcl
```

Paths like `http_directory` and `cloud-init_path` are resolved from the template directory, so the above command works when run from `packer/proxmox/`.

## MicroOS template

- `root` SSH login with password is enabled so Packer can complete provisioning,
- `qemu-guest-agent` is required for IP detection,
- `cloud-init` is installed in the base image for use in cloned VMs,
- `autoinst.xml` file has been generated from basic microos installation and was modified with above settings.

## Known issues

1. Upload issue is caused by proxmox-iso packer plugin integration, this command can start working after a few retries.

```sh
--> proxmox-iso.linux: Post "https://192.168.1.20:8006/api2/json/nodes/t620/storage/local/upload": write tcp 192.168.1.101:65122->192.168.1.20:8006: use of closed network connection
```

2. When multiple host network interfaces are active (e.g., Wi-Fi and Ethernet, or even Docker bridge), AutoYaST may bind to the wrong one and use a different network than the Proxmox node. Disable Wi-Fi and Docker during deployment, or set the network interface manually in the packer configuration,
3. Not able to use checksum with microos - it is a rolling release, and checksums might change with the same download URL.
