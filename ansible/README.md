# Ansible

## MicroOS customization

Ansible is used for post-provision customization, including software installation.

Current role behavior for `microos-media`:

- runs `transactional-update -n up`,
- installs packages from `packages` (default: `podman`, `podman-compose`),
- reboots only when update/install changed the system.

Default package list is in [roles/microos-media/defaults/main.yaml](roles/microos-media/defaults/main.yaml).

1. Fill host vars from example (preferably with 1Password).
2. Execute playbook: `ansible-playbook run.yaml`
