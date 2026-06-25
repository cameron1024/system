#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/.env" 2>/dev/null || true

# Static lease assigned in ./deploy.sh
AP_HOST="admin@192.168.1.3"

# --- wifi -------------------------------------------------------------
AP_COUNTRY="United Kingdom"

# Put the cAP on DIFFERENT channels from the Flint 2 (which uses 2.4=11,
# 5=149) so the two APs don't talk over each other on the air.
AP_CHANNEL_2G_FREQ="${AP_CHANNEL_2G_FREQ:-2412}"   # channel 1
AP_CHANNEL_5G_FREQ="${AP_CHANNEL_5G_FREQ:-5180}"   # channel 36

# Radio generation. cAP ax -> *-ax ; cAP ac -> 2ghz-n / 5ghz-ac.
AP_BAND_2G="${AP_BAND_2G:-2ghz-ax}"
AP_BAND_5G="${AP_BAND_5G:-5ghz-ax}"

# Public key installed by the `keys` subcommand (RouterOS has no ssh-copy-id).
AP_SSH_PUBKEY="${AP_SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"

do_apply() {
    : "${ROUTER_SSID:?set ROUTER_SSID in .env}"
    : "${ROUTER_WIFI_PASSWORD:?set ROUTER_WIFI_PASSWORD in .env}"
    : "${ROUTER_AP_PASSWORD:?set ROUTER_AP_PASSWORD in .env}"

    local ap_user="${AP_HOST%@*}"

    echo "=== Applying configuration to $AP_HOST ==="
    # Pipe the commands straight into the RouterOS console over SSH. RouterOS
    # runs each line immediately (no staging); the :if guards make re-running
    # safe, and full paths keep each line self-contained. Errors print inline
    # but don't abort the rest.
    ssh "$AP_HOST" <<RSC
# Identity
/system identity set name="cap-ap"

# Admin password (from ROUTER_AP_PASSWORD; does not drop the current session)
/user set [find name="$ap_user"] password="$ROUTER_AP_PASSWORD"

# Dumb AP: ensure a bridge exists and every ethernet port is a member of it
:if ([:len [/interface bridge find name="bridge"]] = 0) do={ /interface bridge add name="bridge" }
:foreach e in=[/interface ethernet find] do={ :local en [/interface ethernet get \$e name]; :if ([:len [/interface bridge port find interface=\$en]] = 0) do={ /interface bridge port add bridge=bridge interface=\$en } }

# Get an address from the Flint 2's DHCP; serve no DHCP of our own; don't NAT
:if ([:len [/ip dhcp-client find interface=bridge]] = 0) do={ /ip dhcp-client add interface=bridge disabled=no }
/ip dhcp-server disable [find]
/ip firewall nat disable [find action=masquerade]

# Radios (wifi1 = 5 GHz, wifi2 = 2.4 GHz; swap default-names if your unit differs).
# Everything is set inline on the interface (SSID, passphrase, datapath, steering)
# so this apply is authoritative: inline settings override the named profiles
# that first-time setup / the MikroTik app writes, which would otherwise win.
# Vendor-agnostic assisted roaming: steering.rrm = 802.11k (neighbour reports),
# steering.wnm = 802.11v (BSS transition). security.ft=no leaves out 802.11r.
/interface wifi set [find default-name=wifi1] disabled=no configuration.mode=ap configuration.country="$AP_COUNTRY" configuration.ssid="$ROUTER_SSID" security.authentication-types=wpa2-psk,wpa3-psk security.passphrase="$ROUTER_WIFI_PASSWORD" security.ft=no steering.rrm=yes steering.wnm=yes datapath.bridge=bridge channel.band=$AP_BAND_5G channel.frequency=$AP_CHANNEL_5G_FREQ channel.width=20/40/80mhz
/interface wifi set [find default-name=wifi2] disabled=no configuration.mode=ap configuration.country="$AP_COUNTRY" configuration.ssid="$ROUTER_SSID" security.authentication-types=wpa2-psk,wpa3-psk security.passphrase="$ROUTER_WIFI_PASSWORD" security.ft=no steering.rrm=yes steering.wnm=yes datapath.bridge=bridge channel.band=$AP_BAND_2G channel.frequency=$AP_CHANNEL_2G_FREQ channel.width=20mhz
RSC
    echo "Done."
}

do_show() {
    ssh "$AP_HOST" "
        /interface wifi print
        /interface wifi security print
        /interface wifi registration-table print
    "
}

# Install an SSH public key for the AP_HOST user. RouterOS has no ssh-copy-id
# (its SSH drops you into the RouterOS CLI, not a POSIX shell), so we upload the
# .pub file and import it via /user ssh-keys. Additive: re-running adds another
# entry, so it's safe alongside any keys you manage by hand.
do_keys() {
    [ -f "$AP_SSH_PUBKEY" ] || {
        echo "Public key not found: $AP_SSH_PUBKEY (override with AP_SSH_PUBKEY)" >&2
        exit 1
    }

    local user="${AP_HOST%@*}"
    local fname
    fname="$(basename "$AP_SSH_PUBKEY")"

    echo "=== Uploading $AP_SSH_PUBKEY to AP ==="
    scp "$AP_SSH_PUBKEY" "$AP_HOST:$fname"

    echo "=== Importing key for user '$user' ==="
    ssh "$AP_HOST" "/user ssh-keys import user=$user public-key-file=$fname; /file remove $fname"

    echo "=== Installed keys ==="
    ssh "$AP_HOST" "/user ssh-keys print"
    echo "Done. Key auth should now work: ssh $AP_HOST"
}

case "${1:-}" in
    keys)  do_keys ;;
    apply) do_apply ;;
    show)  do_show ;;
    *)
        echo "Usage: ./deploy_ap.sh <keys|apply|show>" >&2
        exit 1
        ;;
esac
