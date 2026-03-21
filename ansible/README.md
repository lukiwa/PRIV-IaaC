# Ansible

## MicroOS customization

Ansible is used for post-provision customization, including software installation.

Current role behavior for `microos_media`:

- runs `transactional-update -n up`,
- installs packages from `packages` (default: `podman`, `podman-compose`),
- uses `podman-compose` as an aggregator for enabled stacks,
- runs only stacks listed in `podman_compose_selected_stacks` (currently `media`),
- supports stack-level modes: `update` and `deploy`,
- reboots only when update/install changed the system.

Default package list is in [roles/microos_media/defaults/main.yaml](roles/microos_media/defaults/main.yaml).

By default, compose stacks are stored under: `/home/{{ ansible_user }}/podman-compose/<stack-name>`.

Media stack defaults:

- config (bind mount): `/home/{{ ansible_user }}/podman-compose/media/data/{{ plex_container_name }}`
- media: `/var/mnt/external/{tv,movies,music}`

Container config directories follow the convention: `/data/<container_name>` inside the compose project.

### Operation modes

- `podman_compose_operation: update`
  - renders compose/preferences,
  - runs `podman-compose up -d`.

- `podman_compose_operation: deploy`
  - generates fresh Plex claim token from `plex_x_plex_token`,
  - injects `PLEX_CLAIM` into compose for this run,
  - runs `podman-compose up -d --force-recreate`.

### Stacks

Stacks are defined in `podman_compose_stacks` in [roles/microos_media/defaults/main.yaml](roles/microos_media/defaults/main.yaml).
Each stack can point to its own task file and compose template.
Plex-specific actions (for example `Preferences.xml`) live in media stack tasks.

To run only chosen stacks, set `podman_compose_selected_stacks`.
Current default:

- `media`

Stack templates layout:

- compose: `roles/microos_media/templates/stacks/media/compose.yaml.j2`
- preferences: `roles/microos_media/templates/stacks/media/Preferences.xml.j2`

1. Install required collections: `ansible-galaxy collection install -r requirements.yml`
2. Fill host vars from example (preferably with 1Password).
3. Execute playbook: `ansible-playbook run.yaml`

## Plex Claim

1. Plex is known to be fussy when it comes to claiming server from different VLAN. This is a case in this setup,
2. Thus, `PLEX_CLAIM` env var should be passed to a container before first start
3. This `PLEX_CLAIM` is using: `curl -X GET https://plex.tv/api/claim/token\?\&X-Plex-Token\=\{$(op read op://Shared/Plex/X-Plex-Token)\}`
4. X-Plex-Token is stored in 1Password and can be obtained: <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>
5. PLEX_CLAIM is valid for 4m,

## Notes

When repovisioning VM, remember to delete old entries from `known_hosts` login for the first time to add key to known host and try using sudo.
