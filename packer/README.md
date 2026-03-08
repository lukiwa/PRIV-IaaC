# packer/proxmox

## Generating token

WIP
yast2
autoyast2-install
autoyast2

packer init config.pkr.hcl

packer validate -var-file='variables.pkr.hcl' -var-file='variables_secrets.pkr.hcl' proxmox-iso-microos.pkr.hcl

packer build -var-file='variables.pkr.hcl' -var-file='variables_secrets.pkr.hcl' proxmox-iso-microos.pkr.hcl

Manually add PVEDataStoreUser to local for token.
