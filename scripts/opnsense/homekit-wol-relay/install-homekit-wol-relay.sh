#!/bin/sh
# Edit this JSON block in your private copy on OPNsense before installation.
# request_macs accepts multiple incoming wake targets; target_mac is the TV MAC.
RELAY_CONFIG='{
  "source_interface": "HOME_INTERFACE",
  "target_interface": "TV_INTERFACE",
  "target_ip": "TV_IPV4_ADDRESS",
  "source_mac": "HOME_HUB_MAC",
  "request_macs": ["HOMEKIT_REQUEST_MAC", "TV_WIFI_MAC"],
  "target_mac": "TV_WIFI_MAC",
  "cooldown_seconds": 3
}'

set -eu
if [ "$(uname -s)" != "FreeBSD" ] || [ "$(id -u)" != "0" ]; then
    printf '%s\n' 'Run this installer as root on OPNsense.' >&2
    exit 1
fi
for required in /usr/local/bin/python3 /usr/sbin/tcpdump /usr/local/bin/wol /usr/sbin/daemon /sbin/ifconfig; do
    if [ ! -x "$required" ]; then
        printf 'Missing required program: %s\n' "$required" >&2
        exit 1
    fi
done
for destination in \
    /usr/local/libexec/homekit-wol-relay.py \
    /usr/local/etc/homekit-wol-relay.json \
    /usr/local/etc/rc.d/homekit_wol_relay \
    /usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay \
    /usr/local/etc/rc.syshook.d/stop/99-homekit-wol-relay; do
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        printf 'Already exists: %s. No files have been changed.\n' "$destination" >&2
        exit 1
    fi
done

# Stage and validate everything before creating installed service files.
umask 077
relay_tmp=$(mktemp -d /tmp/homekit-wol-relay.XXXXXX)
trap 'rm -rf "$relay_tmp"' 0
trap 'exit 1' 1 2 15
printf '%s\n' "$RELAY_CONFIG" > "$relay_tmp/homekit-wol-relay.json"
cat > "$relay_tmp/homekit-wol-relay.py" <<'HOMEKIT_RELAY_FILE_0_END'
#!/usr/local/bin/python3
"""Relay one configured HomePod's Ethernet wake requests through os-wol."""
import argparse
import ipaddress
import json
import logging
import re
import signal
import struct
import subprocess
import sys
import time

TCPDUMP = '/usr/sbin/tcpdump'
IFCONFIG = '/sbin/ifconfig'
WOL = '/usr/local/bin/wol'
LOG = logging.getLogger('homekit_wol_relay')


def mac_bytes(value):
    if not isinstance(value, str) or not re.fullmatch(r'(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}', value):
        raise ValueError('Invalid MAC address')
    return bytes.fromhex(value.replace(':', ''))


def load_config(path):
    with open(path, encoding='utf-8') as stream:
        cfg = json.load(stream)
    # Keep existing single-address configurations readable during an upgrade.
    if 'request_mac' in cfg and 'request_macs' not in cfg:
        cfg['request_macs'] = [cfg.pop('request_mac')]
    expected = {'source_interface', 'target_interface', 'target_ip', 'source_mac',
                'request_macs', 'target_mac', 'cooldown_seconds'}
    if set(cfg) != expected:
        raise ValueError('Configuration fields do not match the expected schema')
    for key in ('source_interface', 'target_interface'):
        if not isinstance(cfg[key], str) or not re.fullmatch(r'[A-Za-z0-9_.:-]+', cfg[key]):
            raise ValueError('Invalid interface name')
    if cfg['source_interface'] == cfg['target_interface']:
        raise ValueError('Source and target interfaces must differ')
    ipaddress.IPv4Address(cfg['target_ip'])
    for key in ('source_mac', 'target_mac'):
        mac_bytes(cfg[key])
    if not isinstance(cfg['request_macs'], list) or not cfg['request_macs']:
        raise ValueError('request_macs must be a non-empty array of MAC addresses')
    for value in cfg['request_macs']:
        mac_bytes(value)
    if isinstance(cfg['cooldown_seconds'], bool) or not isinstance(cfg['cooldown_seconds'], (int, float)):
        raise ValueError('Invalid cooldown')
    if not 1 <= cfg['cooldown_seconds'] <= 60:
        raise ValueError('Cooldown must be between 1 and 60 seconds')
    return cfg


def read_exact(stream, size):
    chunks = bytearray()
    while len(chunks) < size:
        part = stream.read(size - len(chunks))
        if not part:
            if chunks:
                raise ValueError('Truncated PCAP')
            return None
        chunks.extend(part)
    return bytes(chunks)


def pcap_frames(stream):
    header = read_exact(stream, 24)
    if header is None:
        return
    magics = {b'\xd4\xc3\xb2\xa1': '<', b'\xa1\xb2\xc3\xd4': '>',
              b'\x4d\x3c\xb2\xa1': '<', b'\xa1\xb2\x3c\x4d': '>'}
    endian = magics.get(header[:4])
    if endian is None:
        raise ValueError('Unsupported PCAP format')
    if struct.unpack_from(endian + 'I', header, 20)[0] != 1:
        raise ValueError('Ethernet PCAP required')
    while True:
        record = read_exact(stream, 16)
        if record is None:
            return
        length = struct.unpack_from(endian + 'I', record, 8)[0]
        if length > 262144:
            raise ValueError('Oversized PCAP record')
        frame = read_exact(stream, length)
        if frame is None:
            raise ValueError('Missing PCAP record data')
        yield frame


def matches_request(frame, cfg):
    if len(frame) < 116 or frame[12:14] != b'\x08\x42':
        return False
    source = mac_bytes(cfg['source_mac'])
    requested = frame[20:26]
    accepted = {mac_bytes(value) for value in cfg['request_macs']}
    if frame[6:12] != source or requested not in accepted:
        return False
    if frame[:6] not in (requested, b'\xff' * 6):
        return False
    # Check the whole magic sequence, not just a MAC in an Ethernet header.
    return frame[14:116] == b'\xff' * 6 + requested * 16


def broadcast_for_tv(cfg):
    output = subprocess.check_output(
        [IFCONFIG, cfg['target_interface'], 'inet'], text=True, timeout=5)
    pattern = (r'\binet\s+([0-9.]+)\s+netmask\s+(0x[0-9a-fA-F]+|[0-9.]+)'
               r'[^\n]*?\bbroadcast\s+([0-9.]+)')
    tv = ipaddress.IPv4Address(cfg['target_ip'])
    for address, mask, broadcast in re.findall(pattern, output):
        if mask.startswith('0x'):
            mask = str(ipaddress.IPv4Address(int(mask, 16)))
        network = ipaddress.IPv4Network(address + '/' + mask, strict=False)
        if tv in network and str(network.broadcast_address) == broadcast:
            return broadcast
    raise RuntimeError('Target interface has no IPv4 subnet containing the TV')


def emit_wake(cfg, request_mac):
    broadcast = broadcast_for_tv(cfg)
    # Exactly the sender and arguments used by the os-wol backend. No API keys.
    subprocess.run([WOL, '-i', broadcast, cfg['target_mac']], check=True, timeout=5)
    LOG.info('HomePod wake request for %s -> WoL to %s on %s (%s)',
             request_mac, cfg['target_mac'], cfg['target_interface'], broadcast)


def run_live(cfg):
    state = {'stopping': False, 'capture': None}

    def stop(_signum, _frame):
        state['stopping'] = True
        child = state['capture']
        if child is not None and child.poll() is None:
            child.terminate()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    # Receive only raw WoL from this HomePod. Python additionally validates the
    # destination and complete target-MAC repetition before starting os-wol.
    packet_filter = 'ether proto 0x0842 and ether src ' + cfg['source_mac']
    capture = subprocess.Popen(
        [TCPDUMP, '-p', '-n', '-U', '-s', '256', '-i', cfg['source_interface'],
         '-w', '-', packet_filter], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE)
    state['capture'] = capture
    if state['stopping']:
        capture.terminate()
    last_wake = float('-inf')
    LOG.info('Listening on %s; accepted triggers %s; TV Wi-Fi target %s',
             cfg['source_interface'], cfg['request_macs'], cfg['target_mac'])
    try:
        for frame in pcap_frames(capture.stdout):
            if state['stopping']:
                break
            if matches_request(frame, cfg):
                now = time.monotonic()
                if now - last_wake >= cfg['cooldown_seconds']:
                    emit_wake(cfg, frame[20:26].hex(':'))
                    last_wake = now
        if not state['stopping']:
            raise RuntimeError('Packet capture ended unexpectedly')
    finally:
        if capture.poll() is None:
            capture.terminate()
        try:
            capture.wait(timeout=3)
        except subprocess.TimeoutExpired:
            capture.kill()
            capture.wait()
        capture.stdout.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='/usr/local/etc/homekit-wol-relay.json')
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--check-config', action='store_true')
    modes.add_argument('--replay', metavar='PCAP', help='Classify a saved capture; NEVER sends WoL')
    args = parser.parse_args()
    cfg = load_config(args.config)
    if args.check_config:
        print('Configuration OK')
        return
    if args.replay:
        with open(args.replay, 'rb') as stream:
            matched = sum(matches_request(frame, cfg) for frame in pcap_frames(stream))
        print(json.dumps({'matched_requests': matched, 'mapped_target_mac': cfg['target_mac'],
                          'packets_sent': 0}))
        return
    run_live(cfg)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')
    try:
        main()
    except Exception:
        LOG.exception('Relay stopped')
        sys.exit(1)
HOMEKIT_RELAY_FILE_0_END
cat > "$relay_tmp/homekit_wol_relay.rc" <<'HOMEKIT_RELAY_FILE_1_END'
#!/bin/sh
# PROVIDE: homekit_wol_relay
# REQUIRE: NETWORKING
# KEYWORD: shutdown
. /etc/rc.subr

name="homekit_wol_relay"
rcvar="homekit_wol_relay_enable"
load_rc_config "$name"
: ${homekit_wol_relay_enable:="NO"}

pidfile="/var/run/${name}.pid"
command="/usr/sbin/daemon"
procname="/usr/sbin/daemon"
command_args="-f -P ${pidfile} -r -R 5 -S -T ${name} /usr/local/bin/python3 -u /usr/local/libexec/homekit-wol-relay.py --config /usr/local/etc/homekit-wol-relay.json"
required_files="/usr/local/libexec/homekit-wol-relay.py /usr/local/etc/homekit-wol-relay.json"
start_precmd="homekit_wol_relay_check"

homekit_wol_relay_check()
{
    /usr/local/bin/python3 /usr/local/libexec/homekit-wol-relay.py --check-config
}

run_rc_command "$1"
HOMEKIT_RELAY_FILE_1_END
cat > "$relay_tmp/start-hook.sh" <<'HOMEKIT_RELAY_FILE_2_END'
#!/bin/sh
exec /usr/local/etc/rc.d/homekit_wol_relay onestart
HOMEKIT_RELAY_FILE_2_END
cat > "$relay_tmp/stop-hook.sh" <<'HOMEKIT_RELAY_FILE_3_END'
#!/bin/sh
if /usr/local/etc/rc.d/homekit_wol_relay onestatus >/dev/null 2>&1; then
    exec /usr/local/etc/rc.d/homekit_wol_relay onestop
fi
exit 0
HOMEKIT_RELAY_FILE_3_END

/usr/local/bin/python3 "$relay_tmp/homekit-wol-relay.py" --config "$relay_tmp/homekit-wol-relay.json" --check-config
/usr/local/bin/python3 - "$relay_tmp/homekit-wol-relay.json" <<'HOMEKIT_RELAY_VALIDATE_END'
import json
import subprocess
import sys

with open(sys.argv[1], encoding='utf-8') as stream:
    cfg = json.load(stream)
for key in ('source_interface', 'target_interface'):
    subprocess.run(['/sbin/ifconfig', cfg[key]], check=True, stdout=subprocess.DEVNULL)
HOMEKIT_RELAY_VALIDATE_END

install -d -m 755 /usr/local/libexec /usr/local/etc/rc.d \
    /usr/local/etc/rc.syshook.d/start /usr/local/etc/rc.syshook.d/stop
install -m 755 "$relay_tmp/homekit-wol-relay.py" /usr/local/libexec/homekit-wol-relay.py
install -m 640 "$relay_tmp/homekit-wol-relay.json" /usr/local/etc/homekit-wol-relay.json
install -m 755 "$relay_tmp/homekit_wol_relay.rc" /usr/local/etc/rc.d/homekit_wol_relay
install -m 755 "$relay_tmp/start-hook.sh" /usr/local/etc/rc.syshook.d/start/99-homekit-wol-relay
install -m 755 "$relay_tmp/stop-hook.sh" /usr/local/etc/rc.syshook.d/stop/99-homekit-wol-relay
/usr/local/etc/rc.d/homekit_wol_relay onestart
sleep 1
/usr/local/etc/rc.d/homekit_wol_relay onestatus
printf '%s\n' 'Installed with autostart enabled. Test TV power-on from Apple Home or the home hub.'
