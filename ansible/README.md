# Ansible

## Media VM customization

Ansible is used for post-provision customization, including software installation and container orchestration.

### How it works

- Installs packages from `media_packages` (default: `podman`, `tree`).
- Orchestrates containers defined in `media_containers` (see [roles/media/defaults/main.yaml](roles/media/defaults/main.yaml)).
- Uses Podman Quadlet (`~/.config/containers/systemd/*.container`) for systemd-managed containers.
- Supports two operation modes: `deploy` (full redeploy, data wipe, fresh secrets) and `update` (safe update, no data loss).
- You can run all containers or only selected ones (see below).
- You can run only packages, only containers, or both (using tags).

### Declaring containers

Containers are defined explicitly in `media_containers` in [roles/media/vars/main.yaml](roles/media/vars/main.yaml):

```yaml
media_containers:
  - name: plex
    task: containers/plex.yaml
    config_dir: "{{ media_data_dir }}/plex"
    restart_after_deploy: true
    meta:
      env: {}
      x_plex_token: "{{ media_plex_x_plex_token }}"
      preferences:
        MetricsEpoch: "1"
        # ... other preferences
  # Add more containers here
```

Each container has:

- `name`: container name
- `task`: path to task file
- `config_dir`: config directory
- `restart_after_deploy`: whether to restart after deploy
- `meta`: container-specific config (env vars, tokens, preferences)

To select which containers to deploy/update, set `media_containers_selected` (empty = all):

```yaml
media_containers_selected: []  # or e.g. ["plex"]
```

### Operation modes

- `media_operation: deploy` — full redeploy, stops and disables containers, wipes data, injects fresh secrets, restarts everything from scratch.
- `media_operation: update` — only updates container definitions and restarts if needed, no data loss.

Override on the command line:

```bash
ansible-playbook run.yaml -e 'media_operation=update'
```

Default: `deploy` (see defaults/main.yaml)

### Selective execution

You can selectively run only chosen parts of the media role using tags and the `media_containers_selected` variable.

**1. Only install packages:**

```bash
ansible-playbook run.yaml --tags packages
```

**2. Only containers (all selected in `media_containers_selected`):**

```bash
ansible-playbook run.yaml --tags containers
```

**3. Only selected containers (e.g., only Plex):**

```bash
ansible-playbook run.yaml --tags containers -e 'media_containers_selected=["plex"]'
```

**4. Only selected containers (e.g., Plex and Radarr):**

```bash
ansible-playbook run.yaml --tags containers -e 'media_containers_selected=["plex","radarr"]'
```

**5. Everything (default, no tags):**

```bash
ansible-playbook run.yaml
```

### Usage

1. Install required collections: `ansible-galaxy collection install -r requirements.yml`
2. Fill host vars from example (preferably with 1Password).
3. Execute playbook: `ansible-playbook run.yaml`

### Plex Claim

- Plex requires a claim token for first-time setup. Set `media_plex_x_plex_token` in host_vars (see [Plex docs](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)).
- The token is injected automatically during `deploy` via `meta.x_plex_token`.

### Notes

When reprovisioning VM, remember to delete old entries from `known_hosts` and use sudo for first login if needed.
