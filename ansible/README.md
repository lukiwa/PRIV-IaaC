# Ansible

## Media VM customization

Ansible is used for post-provision customization, including software installation.

Current role behavior for `media`:

- runs `transactional-update -n up`,
- installs packages from `media_packages` (default: `podman`, `tree`),
- uses Podman Quadlet (`~/.config/containers/systemd/*.container`) for enabled stacks,
- runs only stacks listed in `media_quadlet_selected_stacks` (currently `media`),
- supports stack-level modes: `update` and `deploy`,
- reboots only when update/install changed the system.

Default package list is in [roles/media/defaults/main.yaml](roles/media/defaults/main.yaml).

By default, stack data is stored under: `/var/lib/media/stacks/<stack-name>`.
Quadlet units are stored under: `/home/{{ ansible_user }}/.config/containers/systemd`.

Media stack defaults:

- config (bind mount): `/var/lib/media/stacks/media/data/{{ plex_container_name }}`
- media: `/var/mnt/external/{tv,movies,music}`

Container config directories follow the convention: `/data/<container_name>` inside stack data dir.

### Operation modes

- `operation: update`
  - renders Quadlet container unit,
  - runs `systemctl --user enable --now container-<name>.service`.

- `operation: deploy`
  - stops and disables unit,
  - recreates stack data,
  - generates fresh Plex claim token from `media_plex_x_plex_token`,
  - injects `PLEX_CLAIM` into Quadlet unit for this run,
  - enables and starts unit, then restarts it after short pause.

### Stacks

Stacks are defined in `media_quadlet_stacks` in [roles/media/defaults/main.yaml](roles/media/defaults/main.yaml).
Each stack can point to its own task file and is rendered as Quadlet via `containers.podman.podman_container` (`state: quadlet`).
Plex-specific actions (for example `Preferences.xml`) live in media stack tasks.

To run only chosen stacks, set `media_quadlet_selected_stacks`.
Current default:

- `media`

Stack templates layout:

- preferences: `roles/media/templates/stacks/media/Preferences.xml.j2`

## Usage

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
