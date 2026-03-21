# Terraform / Proxmox

This directory is the Terraform root module for Proxmox.

Shared files:

- [providers.tf](providers.tf) - common provider and version constraints
- [variables_secrets.tfvars](variables_secrets.tfvars) - shared secrets (local file)

## Stacks

- [t620/microos-media](t620/microos-media) — media containers (Plex, etc.)

Usage:

1. Go to [terraform/proxmox](.)
2. Prepare one secrets file using 1Password `op inject` into `variables_secrets.tfvars`: `op inject -i variables_secrets.tfvars.example -o variables_secrets.tfvars`
3. Run `terraform init`
4. Run `terraform plan -var-file=variables_secrets.tfvars`
5. Run `terraform apply -var-file=variables_secrets.tfvars`

Note: `.terraform.lock.hcl` is created in [terraform/proxmox](.) and shared by all stacks in this root module.

## OPNSense
...

## User+Password vs Proxmox API Token

This stack intentionally uses `pm_user` + `pm_password` (see [providers.tf](providers.tf)) instead of API token auth.

Reason: for this environment (notably VM disk passthrough with `/dev/disk/by-id/...`) token-based auth led to provider/API permission and behavior issues, described in:

- [Proxmox Bugzilla](https://bugzilla.proxmox.com/show_bug.cgi?id=2582)
- [Telmate provider issue](https://github.com/Telmate/terraform-provider-proxmox/issues/1056)

Because of that, root login via API user (`root@pam`) is currently the stable option for this project.
