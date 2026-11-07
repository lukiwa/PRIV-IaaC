# OPNsense scripts

## HomeKit Wake-on-LAN relay

The `homekit-wol-relay` directory contains two standalone scripts:

- `install-homekit-wol-relay.sh` embeds the worker, rc service and startup/shutdown hooks.
- `uninstall-homekit-wol-relay.sh` stops the service and removes its five runtime files.

The relay listens for raw Ethernet WoL (`0x0842`) from a configured home hub and
uses the existing **os-wol** sender to wake a television on another subnet. It
accepts several requested MAC addresses and always sends to the configured TV
MAC. It validates the full magic packet and limits duplicate requests with a
shared cooldown. The target broadcast is read from the target interface's IPv4
subnet containing the TV address. It does not accept UDP WoL as input.

### Installation

Requires OPNsense/FreeBSD, root, os-wol, Python 3, tcpdump and daemon. No packages
are downloaded. From the repository root on your workstation, replace
`OPNSENSE_ADDRESS`:

```sh
scp -r scripts/opnsense/homekit-wol-relay root@OPNSENSE_ADDRESS:/root/
```

On OPNsense, edit the `RELAY_CONFIG` JSON block at the top of your private copy
of the installer:

```sh
chmod 700 /root/homekit-wol-relay
vi /root/homekit-wol-relay/install-homekit-wol-relay.sh
```

| Field | Value |
| --- | --- |
| `source_interface` | OPNsense device name on the home hub's subnet, as shown by `ifconfig` |
| `target_interface` | OPNsense device name on the TV's subnet |
| `target_ip` | TV IPv4 address |
| `source_mac` | Actual source MAC of the home hub sending WoL |
| `request_macs` | Array of accepted MAC addresses in incoming magic packets |
| `target_mac` | Confirmed TV interface MAC that successfully wakes it |
| `cooldown_seconds` | Minimum interval between outgoing wake packets, from 1 to 60 seconds |

The interfaces must differ. Replace all placeholders, keeping valid JSON.
Keep the repository installer as a template without private network addresses.
Private configuration backups named `scripts/opnsense/*.local.json` are ignored
by Git.

```sh
sh /root/homekit-wol-relay/install-homekit-wol-relay.sh
service homekit_wol_relay onestatus
```

The installer validates configuration and interface names before installing.
It creates five runtime files: the worker under `/usr/local/libexec`, JSON under
`/usr/local/etc`, the rc service under `/usr/local/etc/rc.d`, and start/stop hooks
under `/usr/local/etc/rc.syshook.d`. It starts the service immediately and enables
autostart after network startup. Test power-on from Apple Home or the home hub
with the television asleep. Syslog uses the tag `homekit_wol_relay`.

The installer refuses to overwrite an existing installation. Before an upgrade,
save any settings from `/usr/local/etc/homekit-wol-relay.json` and update the
configuration block in the new installer. Then uninstall and install again.

Files under `/root` survive reboots. Keep an external backup of your configured
installer: these custom files are not included in the OPNsense `config.xml` backup.

### Service commands

After editing `/usr/local/etc/homekit-wol-relay.json`, restart:

```sh
service homekit_wol_relay onerestart
```

Stop and disable autostart:

```sh
chmod -x /usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay
service homekit_wol_relay onestop
```

Enable again:

```sh
chmod +x /usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay
service homekit_wol_relay onestart
```

Uninstall:

```sh
sh /root/homekit-wol-relay/uninstall-homekit-wol-relay.sh
```

This leaves os-wol, its saved hosts and the two source scripts under `/root` intact.

### References

- [os-wol sender](https://github.com/opnsense/plugins/blob/master/net/wol/src/opnsense/service/conf/actions.d/actions_wol.conf)
- [OPNsense start/stop hooks](https://docs.opnsense.org/development/backend/autorun.html)
- [FreeBSD daemon supervisor](https://github.com/freebsd/freebsd-src/blob/main/usr.sbin/daemon/daemon.8)
