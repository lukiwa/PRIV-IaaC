# Ansible

## MicroOS customization

Ansible is used for post-provision customization, including software installation.

Current role behavior for `microos-media`:

- runs `transactional-update -n up`,
- installs packages from `packages` (default: `podman`, `podman-compose`),
- deploys a single rootless `podman-compose` stack with `plex`,
- reboots only when update/install changed the system.

Default package list is in [roles/microos-media/defaults/main.yaml](roles/microos-media/defaults/main.yaml).

By default, compose files are stored in user home: `/home/{{ ansible_user }}/podman-compose/media`.

Default Plex paths:

- config (bind mount): `/home/{{ ansible_user }}/podman-compose/media/data/plex-config`
- media: `/var/mnt/external/{tv,movies,music}`

Plex `PUID`/`PGID` are auto-detected from `podman_compose_user`.

1. Install required collections: `ansible-galaxy collection install -r requirements.yml`
2. Fill host vars from example (preferably with 1Password).
3. Execute playbook: `ansible-playbook run.yaml`
