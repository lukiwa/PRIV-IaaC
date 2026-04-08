# Ansible

Post-provision customization for MicroOS VMs: package installation and Podman Quadlet container orchestration.

Each VM has a dedicated role. `run.yaml` runs a separate play per host.

| Host | Role | Vars |
| --- | --- | --- |
| `media` | `roles/media` | [roles/media/vars/main.yaml](roles/media/vars/main.yaml) |
| `infra` | `roles/infra` | [roles/infra/vars/main.yaml](roles/infra/vars/main.yaml) |

## Usage

```bash
# 1. Install required collections
ansible-galaxy collection install -r requirements.yml

# 2. Populate host_vars from 1Password
./setup.sh

# 3. Run everything
ansible-playbook run.yaml

# 4. Limit to a single host
ansible-playbook run.yaml --limit media
ansible-playbook run.yaml --limit infra
```

> [!NOTE]
> Always use JSON format (`-e '{"key": value}'`) when passing lists or booleans. The `key=value` shorthand always passes a string, which breaks list variables.

## How it works

- Installs packages from `<role>_packages`.
- Orchestrates containers defined in `<role>_containers`.
- Uses Podman Quadlet for systemd-managed containers.
  - User-scope: `~/.config/containers/systemd/`
  - System-scope (e.g. gluetun): `/etc/containers/systemd/`
- Idempotent — directories are created if missing, quadlet definitions are updated, services are restarted only when the definition changes.
- Container-specific provisioning (e.g. Plex `Preferences.xml`) runs only on first deploy, unless `force_reprovision: true` is set in `meta`.

## Declaring containers

```yaml
<role>_containers:
  - name: mycontainer
    task: containers/mycontainer.yaml   # relative to roles/<role>/tasks/
    config_dir: "{{ <role>_data_dir }}/mycontainer"
    system_service: true                # optional, default: false (user scope)
    network:                            # optional, default: [host]
      - podman
    ports:                              # optional
      - "8080:8080"
    quadlet_options_extra:              # optional
      - |
        [Service]
        TimeoutStartSec=120
    meta:
      env:
        TZ: Europe/Warsaw
```

| Field                   | Default  | Description                                          |
| ----------------------- | -------- | ---------------------------------------------------- |
| `name`                  | —        | container name                                       |
| `task`                  | —        | task file path relative to `roles/<role>/tasks/`     |
| `config_dir`            | —        | config directory on the host                         |
| `system_service`        | `false`  | `true` for root/system-scope containers              |
| `network`               | `[host]` | Podman network list                                  |
| `ports`                 | `[]`     | port mappings (not used with host/container network) |
| `quadlet_options_extra` | `[]`     | additional quadlet options appended to main options  |
| `meta`                  | —        | container-specific data (env vars, tokens, etc.)     |

## Selective execution

```bash
# Only packages
ansible-playbook run.yaml --tags packages

# All containers
ansible-playbook run.yaml --tags containers

# Selected containers (media)
ansible-playbook run.yaml --limit media --tags containers -e '{"media_containers_selected": ["plex"]}'

# Selected containers (infra)
ansible-playbook run.yaml --limit infra --tags containers -e '{"infra_containers_selected": ["hello-world"]}'
```

## Traefik (infra VM)

Traefik runs as a reverse proxy on the infra VM, routing traffic to services on the media VM based on hostname.

The domain scheme is `<service>.<domain>`, where the domain is set via `infra_traefik_domain` (e.g. `t620.home.arpa`).

### DNS

All wildcard entries must point to the infra VM IP.

#### NextDNS — Rewrites

In the NextDNS panel → **Rewrites**, add:

```
*.t620.home.arpa → <infra VM IP>
```

#### OPNsense — Unbound DNS

If not using NextDNS or as a local fallback, add a wildcard override via **Services → Unbound DNS → Custom options**:

```
local-zone: "t620.home.arpa." redirect
local-data: "t620.home.arpa. A <infra VM IP>"
```

> [!NOTE]
> Entries like `*.media-t620.home.arpa` and `*.infra-t620.home.arpa` point to their respective VMs and do not conflict with the Traefik wildcard.

### Routes

| URL | Backend |
|-----|---------|
| `radarr.t620.home.arpa` | media VM :7878 |
| `sonarr.t620.home.arpa` | media VM :8989 |
| `prowlarr.t620.home.arpa` | media VM :9696 |
| `bazarr.t620.home.arpa` | media VM :6767 |
| `qbittorrent.t620.home.arpa` | media VM :8182 |

Dashboard available at `http://<infra VM IP>:8080/dashboard/`.

## Plex

Requires a claim token for first-time setup. Set `media_plex_x_plex_token` in host_vars (see [Plex docs](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)).

To force re-generation of `Preferences.xml`, set `force_reprovision: true` in the Plex container `meta`, run the playbook, then revert.

## Notes

When reprovisioning a VM, delete the old entry from `known_hosts` before running the playbook.
