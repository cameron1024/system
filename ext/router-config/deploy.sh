#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/.env" 2>/dev/null || true

ROUTER="root@192.168.1.1"
MINI_STATIC_IP="192.168.1.2"

do_install() {
    echo "=== Updating packages ==="
    ssh "$ROUTER" "apk update"

    echo "=== Installing packages ==="
    ssh "$ROUTER" "apk add \
        luci-app-sqm \
        sqm-scripts \
        nlbwmon \
        luci-app-nlbwmon \
        luci-mod-rpc \
        nano \
        tcpdump"

    echo "=== Done ==="
}

do_set() {
    echo "=== Staging configuration ==="

    ssh "$ROUTER" '
        uci set system.@system[0].hostname="router"
        uci set system.@system[0].timezone="GMT0BST,M3.5.0/1,M10.5.0"
        uci set system.@system[0].zonename="Europe/London"
    '

    # Don't set network.lan.ipaddr because it's a list, not option
    ssh "$ROUTER" '
        uci set network.wan.proto="pppoe"
    '

    ssh "$ROUTER" '
        uci set wireless.radio0.country="GB"
        uci set wireless.radio0.disabled="0"
        uci set wireless.default_radio0.encryption="sae-mixed"
    '

    ssh "$ROUTER" '
        uci set wireless.radio1.country="GB"
        uci set wireless.radio1.channel="36"
        uci set wireless.radio1.htmode="HE160"
        uci set wireless.radio1.disabled="0"
        uci set wireless.default_radio1.encryption="sae-mixed"
    '

    # https://www.waveform.com/tools/bufferbloat
    ssh "$ROUTER" '
        uci set sqm.wan=queue
        uci set sqm.wan.enabled="1"
        uci set sqm.wan.interface="pppoe-wan"
        uci set sqm.wan.qdisc="cake"
        uci set sqm.wan.script="piece_of_cake.qos"
        uci set sqm.wan.download="36000"
        uci set sqm.wan.upload="7200"
        uci set sqm.wan.linklayer="ethernet"
        uci set sqm.wan.overhead="44"
    '

    ssh "$ROUTER" '
        uci set firewall.@defaults[0].flow_offloading="0"
        uci set firewall.@defaults[0].flow_offloading_hw="0"
    '

    # disable IPv6
    ssh "$ROUTER" '
        uci set network.wan6.auto="0"
        uci set dhcp.lan.dhcpv6="disabled"
        uci set dhcp.lan.ra="disabled"
        uci delete network.globals.ula_prefix 2>/dev/null || true
    '

    # Static DHCP lease for mini + forward DNS to AdGuard Home
    if [ -n "${ROUTER_MINI_MAC:-}" ]; then
        echo "  Setting mini static lease and DNS forwarding"
        ssh "$ROUTER" "
            uci set dhcp.mini=host
            uci set dhcp.mini.name='mini'
            uci set dhcp.mini.mac='$ROUTER_MINI_MAC'
            uci set dhcp.mini.ip='$MINI_STATIC_IP'
        "
        ssh "$ROUTER" '
            uci set dhcp.@dnsmasq[0].noresolv="1"
            uci del_list dhcp.@dnsmasq[0].server="'"$MINI_STATIC_IP"'" 2>/dev/null || true
            uci add_list dhcp.@dnsmasq[0].server="'"$MINI_STATIC_IP"'"
            uci del_list dhcp.@dnsmasq[0].server="1.1.1.1" 2>/dev/null || true
            uci add_list dhcp.@dnsmasq[0].server="1.1.1.1"
        '
    fi

    # Static DHCP lease for TV + block internet access
    if [ -n "${ROUTER_SMART_TV_MAC:-}" ]; then
        echo "  Setting TV static lease"
        ssh "$ROUTER" "
            uci set dhcp.smart_tv=host
            uci set dhcp.smart_tv.name='smart-tv'
            uci set dhcp.smart_tv.mac='$ROUTER_SMART_TV_MAC'
            uci set dhcp.smart_tv.ip='192.168.1.11'
        "
        ssh "$ROUTER" "
            uci set firewall.block_smart_tv=rule
            uci set firewall.block_smart_tv.name='Block Smart TV WAN'
            uci set firewall.block_smart_tv.src='lan'
            uci set firewall.block_smart_tv.dest='wan'
            uci set firewall.block_smart_tv.src_ip='192.168.1.11'
            uci set firewall.block_smart_tv.target='REJECT'
        "
    fi

    if [ -n "${ROUTER_SSID:-}" ]; then
        echo "  Setting WiFi SSID"
        ssh "$ROUTER" "
            uci set wireless.default_radio0.ssid='$ROUTER_SSID'
            uci set wireless.default_radio1.ssid='$ROUTER_SSID'
        "
    fi

    if [ -n "${ROUTER_WIFI_PASSWORD:-}" ]; then
        echo "  Setting WiFi password"
        ssh "$ROUTER" "
            uci set wireless.default_radio0.key='$ROUTER_WIFI_PASSWORD'
            uci set wireless.default_radio1.key='$ROUTER_WIFI_PASSWORD'
        "
    fi

    if [ -n "${ROUTER_PPPOE_USERNAME:-}" ]; then
        echo "  Setting PPPoE username"
        ssh "$ROUTER" "uci set network.wan.username='$ROUTER_PPPOE_USERNAME'"
    fi

    if [ -n "${ROUTER_PPPOE_PASSWORD:-}" ]; then
        echo "  Setting PPPoE password"
        ssh "$ROUTER" "uci set network.wan.password='$ROUTER_PPPOE_PASSWORD'"
    fi

    echo
    echo "Done. Review staged changes with:"
    echo "  ssh $ROUTER \"uci changes\""
    echo
    echo "To apply, run: ./deploy.sh apply"
}

do_apply() {
    echo "=== Committing ==="
    ssh "$ROUTER" '
        uci commit dhcp
        uci commit firewall
        uci commit network
        uci commit sqm
        uci commit system
        uci commit wireless
    '

    echo "=== Rebooting ==="
    ssh "$ROUTER" "reboot"
    echo "Router is rebooting. It should be back in about a minute."
}

case "${1:-}" in
    install) do_install ;;
    set)     do_set ;;
    apply)   do_apply ;;
    sqm-on)  ssh "$ROUTER" "/etc/init.d/sqm start"  && echo "SQM enabled." ;;
    sqm-off) ssh "$ROUTER" "/etc/init.d/sqm stop"   && echo "SQM disabled." ;;
    *)
        echo "Usage: ./deploy.sh <install|set|apply|sqm-on|sqm-off>" >&2
        exit 1
        ;;
esac
