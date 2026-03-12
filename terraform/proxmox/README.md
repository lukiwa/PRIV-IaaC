# Terraform / Proxmox

This directory is the Terraform root module for Proxmox.

Shared files:

- [providers.tf](providers.tf) - common provider and version constraints
- [variables_secrets.tfvars](variables_secrets.tfvars) - shared secrets (local file)

Stacks are defined as Terraform modules (treated here as components), for example:

- [t620/microos-media](t620/microos-media)

Has predefined macaddres, and added static lease for it in OPNSense.

Usage:

1. Go to [terraform/proxmox](.)
2. Prepare secrets (for example using 1Password `op inject` into `variables_secrets.tfvars`). Do this globally and for each component.
3. For each component that needs to be deployed, prepare `module.tf` from `module.tf.example` using 1Password or manually.
4. Run `terraform init`
5. Run `terraform plan -var-file=variables_secrets.tfvars`

Note: `.terraform.lock.hcl` is created in [terraform/proxmox](.) and shared by all stacks in this root module.

## microos-media component SSH

In [t620/microos-media/module.tf](t620/microos-media/module.tf), Cloud-Init is configured with:

- `ciuser = "media-user"`
- `sshkeys = ...` (your public key)

This gives key-based login for `media-user` at component level, without manual uploads to Proxmox snippets.
