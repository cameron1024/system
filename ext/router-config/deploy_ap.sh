#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/.env" 2>/dev/null || true

# Cudy M3000 running OpenWrt, as a dumb AP on the main LAN. The static IP is
# set below; ./deploy.sh should also carry a matching static lease so the
# address stays reserved even if the AP ever falls back to DHCP.
AP="root@192.168.1.4"
AP_IP="192.168.1.4"
ROUTER_IP="192.168.1.1"

# Put the AP on DIFFERENT channels from the Flint 2 (which uses 2.4=11,
# 5=149) so the two APs don't talk over each other on the air.
AP_CHANNEL_2G="${AP_CHANNEL_2G:-1}"
AP_CHANNEL_5G="${AP_CHANNEL_5G:-36}"

# Public key installed by the `keys` subcommand (dropbear has no ~/.ssh, so
# ssh-copy-id doesn't work out of the box).
AP_SSH_PUBKEY="${AP_SSH_PUBKEY:-$HOME/.ssh/id_ed25519.pub}"

do_set() {
    echo "=== Staging configuration ==="

    ssh "$AP" '
        uci set system.@system[0].hostname="cudy-ap"
        uci set system.@system[0].timezone="GMT0BST,M3.5.0/1,M10.5.0"
        uci set system.@system[0].zonename="Europe/London"
    '

    # Dumb AP: a static address on the main LAN, gateway/DNS at the router.
    ssh "$AP" "
        uci set network.lan.proto='static'
        uci set network.lan.ipaddr='$AP_IP'
        uci set network.lan.netmask='255.255.255.0'
        uci set network.lan.gateway='$ROUTER_IP'
        uci set network.lan.dns='$ROUTER_IP'
    "

    # Fold the wan port into the LAN bridge so every port is usable, and
    # drop the wan interfaces entirely (an AP routes nothing).
    ssh "$AP" '
        uci -q delete network.wan
        uci -q delete network.wan6
        uci del_list network.@device[0].ports="wan" 2>/dev/null || true
        uci add_list network.@device[0].ports="wan"
        true
    '

    ssh "$AP" '
        uci set wireless.radio0.country="GB"
        uci set wireless.radio0.channel="'"$AP_CHANNEL_2G"'"
        uci set wireless.radio0.htmode="HE20"
        uci set wireless.radio0.disabled="0"
        uci set wireless.default_radio0.disabled="0"
        uci set wireless.default_radio0.mode="ap"
        uci set wireless.default_radio0.network="lan"
        uci set wireless.default_radio0.encryption="sae-mixed"
    '

    ssh "$AP" '
        uci set wireless.radio1.country="GB"
        uci set wireless.radio1.channel="'"$AP_CHANNEL_5G"'"
        uci set wireless.radio1.htmode="HE80"
        uci set wireless.radio1.disabled="0"
        uci set wireless.default_radio1.disabled="0"
        uci set wireless.default_radio1.mode="ap"
        uci set wireless.default_radio1.network="lan"
        uci set wireless.default_radio1.encryption="sae-mixed"
    '

    # Wifi roaming (802.11k/v) is kept off, matching the router (see
    # deploy.sh: wnm_sleep_mode in particular broke clients). Ensure the
    # options stay absent.
    ssh "$AP" '
        uci -q delete wireless.default_radio0.ieee80211k
        uci -q delete wireless.default_radio0.bss_transition
        uci -q delete wireless.default_radio0.wnm_sleep_mode
        uci -q delete wireless.default_radio1.ieee80211k
        uci -q delete wireless.default_radio1.bss_transition
        uci -q delete wireless.default_radio1.wnm_sleep_mode
        true
    '

    if [ -n "${ROUTER_SSID:-}" ]; then
        echo "  Setting WiFi SSID"
        ssh "$AP" "
            uci set wireless.default_radio0.ssid='$ROUTER_SSID'
            uci set wireless.default_radio1.ssid='$ROUTER_SSID'
        "
    fi

    if [ -n "${ROUTER_WIFI_PASSWORD:-}" ]; then
        echo "  Setting WiFi password"
        ssh "$AP" "
            uci set wireless.default_radio0.key='$ROUTER_WIFI_PASSWORD'
            uci set wireless.default_radio1.key='$ROUTER_WIFI_PASSWORD'
        "
    fi

    # An AP serves no DHCP/DNS and needs no firewall. Like passwd below,
    # these take effect immediately (they are not staged/committed).
    echo "  Disabling dnsmasq/odhcpd/firewall (immediate)"
    ssh "$AP" '
        /etc/init.d/dnsmasq disable && /etc/init.d/dnsmasq stop
        /etc/init.d/odhcpd disable && /etc/init.d/odhcpd stop
        /etc/init.d/firewall disable && /etc/init.d/firewall stop
        true
    '

    # Root password = LuCI web UI login + SSH password auth. Unlike the uci
    # settings above, passwd takes effect immediately.
    if [ -n "${ROUTER_AP_PASSWORD:-}" ]; then
        echo "  Setting AP (LuCI/SSH) password"
        ssh "$AP" "printf '%s\n%s\n' '$ROUTER_AP_PASSWORD' '$ROUTER_AP_PASSWORD' | passwd root"
    fi

    echo
    echo "Done. Review staged changes with:"
    echo "  ssh $AP \"uci changes\""
    echo
    echo "To apply, run: ./deploy_ap.sh apply"
}

do_apply() {
    local reboot=1
    for arg in "$@"; do
        case "$arg" in
            --no-reboot) reboot=0 ;;
            *) echo "Unknown apply option: $arg" >&2; exit 1 ;;
        esac
    done

    echo "=== Committing ==="
    ssh "$AP" '
        uci commit system
        uci commit network
        uci commit wireless
    '

    if [ "$reboot" -eq 1 ]; then
        echo "=== Rebooting ==="
        ssh "$AP" "reboot"
        echo "AP is rebooting. It should be back in about a minute."
        return
    fi

    # --no-reboot: reload each service instead. network/wifi come last
    # because they can briefly drop the link (and your SSH session).
    echo "=== Reloading services (no reboot) ==="
    ssh "$AP" '
        /etc/init.d/system reload
        /etc/init.d/network reload
        wifi reload
    '
    echo "Services reloaded (no reboot performed)."
}

# Install an SSH public key for root. Dropbear reads
# /etc/dropbear/authorized_keys rather than ~/.ssh, so ssh-copy-id doesn't
# work out of the box. Additive: re-running with a new key appends; the same
# key is skipped, so this stays idempotent.
do_keys() {
    [ -f "$AP_SSH_PUBKEY" ] || {
        echo "Public key not found: $AP_SSH_PUBKEY (override with AP_SSH_PUBKEY)" >&2
        exit 1
    }

    echo "=== Installing $AP_SSH_PUBKEY on the AP ==="
    ssh "$AP" "
        mkdir -p /etc/dropbear
        touch /etc/dropbear/authorized_keys
        chmod 600 /etc/dropbear/authorized_keys
        grep -qxF '$(cat "$AP_SSH_PUBKEY")' /etc/dropbear/authorized_keys \
            || echo '$(cat "$AP_SSH_PUBKEY")' >> /etc/dropbear/authorized_keys
    "

    echo "=== Installed keys ==="
    ssh "$AP" "cat /etc/dropbear/authorized_keys"
    echo "Done. Key auth should now work: ssh $AP"
}

do_show() {
    ssh "$AP" '
        wifi status | grep -E "\"(up|ssid|channel)\"" || wifi status
        echo ---
        for i in $(iw dev | awk "/Interface/{print \$2}"); do
            echo "== $i"
            iw dev "$i" station dump | grep -E "^Station|signal:" || true
        done
    '
}

case "${1:-}" in
    keys)    do_keys ;;
    set)     do_set ;;
    apply)   shift; do_apply "$@" ;;
    changes) ssh "$AP" "uci changes" ;;
    show)    do_show ;;
    *)
        echo "Usage: ./deploy_ap.sh <keys|set|apply [--no-reboot]|changes|show>" >&2
        exit 1
        ;;
esac
