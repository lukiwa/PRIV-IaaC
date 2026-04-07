# Ansible

## Media VM customization

Ansible is used for post-provision customization, including software installation and container orchestration.

### How it works

- Installs packages from `media_packages` (default: `podman`, `tree`).
- Orchestrates containers defined in `media_containers` (see [roles/media/vars/main.yaml](roles/media/vars/main.yaml)).
- Uses Podman Quadlet for systemd-managed containers. User-scope containers use `~/.config/containers/systemd/`, system-scope (e.g. gluetun) use `/etc/containers/systemd/`.
- Idempotent — safe to re-run at any time. Directories are created if missing, quadlet definitions are updated, services are restarted only when the definition changes.
- Container-specific provisioning (e.g. Plex `Preferences.xml`) is only done on first run, unless `force_reprovision: true` is set in the container's `meta`.

### Declaring containers

Containers are defined in `media_containers` in [roles/media/vars/main.yaml](roles/media/vars/main.yaml):

```yaml
media_containers:
  - name: mycontainer
    task: containers/mycontainer.yaml   # task file under roles/media/tasks/
    config_dir: "{{ media_data_dir }}/mycontainer"
    system_service: true                # optional, default: false (user scope)
    network:                            # optional, default: [host]
      - media-network
    ports:                              # optional
      - "8080:8080"
    quadlet_options_extra:              # optional, appended to media_quadlet_options_main
      - |
        [Service]
        TimeoutStartSec=120
    meta:                               # container-specific config
      env:
        TZ: Europe/Berlin
```

Container fields:

- `name` — container name
- `task` — path to task file (relative to `roles/media/tasks/`)
- `config_dir` — config directory on the host
- `system_service` — set to `true` for root/system-scope containers (e.g. gluetun); defaults to user scope
- `network` — list of Podman networks; use `host` or `container:<name>` for system containers
- `ports` — port mappings (not needed when using host or container network)
- `quadlet_options_extra` — additional quadlet `[Unit]`/`[Container]`/`[Service]` options
- `meta` — container-specific data (env vars, tokens, etc.)

To select which containers to run, set `media_containers_selected` (empty = all):

```yaml
media_containers_selected: []  # or e.g. ["plex", "radarr"]
```

### Selective execution

```bash
# Only packages
ansible-playbook run.yaml --tags packages

# All containers
ansible-playbook run.yaml --tags containers

# Selected containers
ansible-playbook run.yaml --tags containers -e '{"media_containers_selected": ["plex"]}'

# Everything (default)
ansible-playbook run.yaml
```

**6. Everything (default, no tags):**

```bash
ansible-playbook run.yaml
```

> [!NOTE]
> Always use JSON format (`-e '{"key": value}'`) when passing lists or booleans. The `key=value` shorthand always passes a string, which breaks list variables like `media_containers_selected`.

### Usage

1. Install required collections: `ansible-galaxy collection install -r requirements.yml`
2. Populate host_vars from 1Password: `cd ansible && ./setup.sh`
3. Execute playbook: `ansible-playbook run.yaml`

### Plex

Plex requires a claim token for first-time setup. Set `media_plex_x_plex_token` in host_vars (see [Plex docs](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)).

To force re-generation of `Preferences.xml`, set `force_reprovision: true` in the Plex container `meta` in `vars/main.yaml`, run the playbook, then revert the flag.

### Notes

When reprovisioning VM, remember to delete old entries from `known_hosts` and use sudo for first login if needed.
