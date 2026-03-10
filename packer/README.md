# packer/proxmox

## Generating token

WIP
yast2
autoyast2-install
autoyast2

WIP: autoyast2 -generate command


packer init config.pkr.hcl

packer validate -var-file='variables.pkr.hcl' -var-file='variables_secrets.pkr.hcl' proxmox-iso-microos.pkr.hcl

packer build -var-file='variables.pkr.hcl' -var-file='variables_secrets.pkr.hcl' proxmox-iso-microos.pkr.hcl
