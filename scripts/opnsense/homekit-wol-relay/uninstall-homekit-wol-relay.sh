#!/bin/sh
# Remove only the custom HomeKit wake relay. Keep os-wol and its saved hosts.
set -eu

if [ "$(uname -s)" != "FreeBSD" ] || [ "$(id -u)" != "0" ]; then
    printf '%s\n' 'Run this uninstaller as root on OPNsense.' >&2
    exit 1
fi

relay_rc=/usr/local/etc/rc.d/homekit_wol_relay
relay_start=/usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay

if [ -f "$relay_start" ]; then
    chmod -x "$relay_start"
fi

if [ -x "$relay_rc" ]; then
    if "$relay_rc" onestatus >/dev/null 2>&1; then
        "$relay_rc" onestop
    fi
    if "$relay_rc" onestatus >/dev/null 2>&1; then
        printf '%s\n' 'Relay is still running. No service files have been removed.' >&2
        exit 1
    fi
elif [ -f /var/run/homekit_wol_relay.pid ]; then
    printf '%s\n' 'Service script is missing but a pidfile exists. Check the running relay before removing its files.' >&2
    exit 1
fi

rm -f \
    /usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay \
    /usr/local/etc/rc.syshook.d/stop/99-homekit-wol-relay \
    /usr/local/etc/rc.d/homekit_wol_relay \
    /usr/local/libexec/homekit-wol-relay.py \
    /usr/local/etc/homekit-wol-relay.json

printf '%s\n' 'Custom HomeKit wake relay removed. os-wol and its saved hosts have been kept.'
