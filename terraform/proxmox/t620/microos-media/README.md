# microos-media

VM for media containers (Plex, etc.). MicroOS clone, VMID `1001`, node `t620`.

## External disk

USB HDD passed through as `virtio1`, mounted as NTFS at `/var/mnt/external`. Disk serial number (needed for `external_disk_id`) is in 1Password.

If the disk is not connected during VM startup, remove virtio1 from VM using `qm`.

## OPNSense
Remember to set hostname and static mapping for this VM.

## cloud-init vendor-data

[`cloud-init/vendor-data.yml`](cloud-init/vendor-data.yml) on first boot:

- disables root login (passwd locked, no SSH)
- SSH key-only auth, `PermitRootLogin no`
- `mediauser` gets full sudo (password required)
- mounts `virtio1 part1` as NTFS via `/etc/fstab` with `nofail`
