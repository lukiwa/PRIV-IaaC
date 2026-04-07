locals {
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  secrets = read_terragrunt_config(find_in_parent_folders("secrets.hcl"))
}

remote_state {
  backend = "local"
  config = {
    path = "${get_repo_root()}/.terraform-state/proxmox/t620/${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "proxmox" {
      pm_api_url      = "${local.secrets.locals.proxmox_api_url}"
      pm_user         = "${local.env.locals.proxmox_api_user}"
      pm_password     = "${local.secrets.locals.proxmox_api_password}"
      pm_tls_insecure = true
    }
  EOF
}
