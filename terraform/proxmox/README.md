# Terraform / Proxmox

This directory is the Terraform root module for Proxmox.

Shared files:

- [providers.tf](providers.tf) - common provider and version constraints
- [variables_secrets.tfvars](variables_secrets.tfvars) - shared secrets (local file)

Stacks are defined as modules, for example:

- [t620/microos-media](t620/microos-media)

 Has predefined MAC address, and added static lease for it in OPNSense.

Usage:

1. Go to [terraform/proxmox](.)
2. Prepare one secrets file using 1Password `op inject` into `variables_secrets.tfvars`: `op inject -i variables_secrets.tfvars.example -o variables_secrets.tfvars`
3. Run `terraform init`
4. Run `terraform plan -var-file=variables_secrets.tfvars`
5. Run `terraform apply -var-file=variables_secrets.tfvars`

Note: `.terraform.lock.hcl` is created in [terraform/proxmox](.) and shared by all stacks in this root module.
