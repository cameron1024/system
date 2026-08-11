#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/.env" 2>/dev/null || true

# main network

ROUTER="root@192.168.1.1"
MINI_STATIC_IP="192.168.1.2"
AP_STATIC_IP="192.168.1.3"
WINDOWS_PC_STATIC_IP="192.168.1.12"
AIR1_STATIC_IP="192.168.1.13"

# separate WPA2 iot network

IOT_ROUTER_IP="192.168.2.1"
PRINTER_STATIC_IP="192.168.2.10"

# separate guest network (WAN only, fully isolated from the LAN)

GUEST_ROUTER_IP="192.168.3.1"

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
        uci set wireless.radio0.channel="11"
        uci set wireless.radio0.htmode="HE20"
        uci set wireless.radio0.disabled="0"
        uci set wireless.default_radio0.encryption="sae-mixed"
    '

    ssh "$ROUTER" '
        uci set wireless.radio1.country="GB"
        uci set wireless.radio1.channel="149"
        uci set wireless.radio1.htmode="HE80"
        uci set wireless.radio1.disabled="0"
        uci set wireless.default_radio1.encryption="sae-mixed"
    '

    # Wifi roaming (802.11k/v) was tried here and reverted: wnm_sleep_mode in
    # particular is known to break clients (drops/rekey failures, especially
    # with sae-mixed). Ensure the options stay absent.
    ssh "$ROUTER" '
        uci -q delete wireless.default_radio0.ieee80211k
        uci -q delete wireless.default_radio0.bss_transition
        uci -q delete wireless.default_radio0.wnm_sleep_mode
        uci -q delete wireless.default_radio1.ieee80211k
        uci -q delete wireless.default_radio1.bss_transition
        uci -q delete wireless.default_radio1.wnm_sleep_mode
        true
    '

    # https://www.waveform.com/tools/bufferbloat
    # Plusnet FTTP still uses PPPoE (untagged) over the Openreach ONT, so the
    # interface stays pppoe-wan. Set download/upload to ~95% of your FTTP
    # package sync speed (kbit/s), and use the fibre PPPoE framing overhead (26)
    # instead of the old VDSL2/FTTC value (44, which included PTM framing).
    ssh "$ROUTER" '
        uci set sqm.wan=queue
        uci set sqm.wan.interface="pppoe-wan"
        uci set sqm.wan.qdisc="cake"
        uci set sqm.wan.script="piece_of_cake.qos"
        uci set sqm.wan.download="855000"
        uci set sqm.wan.upload="104000"
        uci set sqm.wan.linklayer="ethernet"
        uci set sqm.wan.overhead="26"
        # cake auto-sizes its egress buffer to ~5.2MB at this rate, and it was
        # observed hitting that ceiling (memory used == limit in `tc -s qdisc`).
        # Bump it ~25% to give upload bursts more headroom.
        uci set sqm.wan.qdisc_advanced="1"
        uci set sqm.wan.qdisc_really_really_advanced="1"
        uci set sqm.wan.eqdisc_opts="memlimit 6500000"
    '

    # SQM and flow offloading are mutually exclusive: SQM must inspect every
    # packet on the CPU, while offloading bypasses it. Enable SQM (and disable
    # offloading) only when ROUTER_ENABLE_SQM is exactly "1"; otherwise turn on
    # hardware flow offloading for maximum throughput.
    if [ "${ROUTER_ENABLE_SQM:-}" = "1" ]; then
        echo "  SQM enabled (flow offloading disabled)"
        ssh "$ROUTER" '
            uci set sqm.wan.enabled="1"
            uci set firewall.@defaults[0].flow_offloading="0"
            uci set firewall.@defaults[0].flow_offloading_hw="0"
        '
    else
        echo "  SQM disabled (hardware flow offloading enabled)"
        ssh "$ROUTER" '
            uci set sqm.wan.enabled="0"
            uci set firewall.@defaults[0].flow_offloading="1"
            uci set firewall.@defaults[0].flow_offloading_hw="1"
        '
    fi

    # disable IPv6
    ssh "$ROUTER" '
        uci set network.wan6.auto="0"
        uci set dhcp.lan.dhcpv6="disabled"
        uci set dhcp.lan.ra="disabled"
        uci delete network.globals.ula_prefix 2>/dev/null || true
    '

    # === Segregated IoT network ============================================
    # A separate WPA2-only SSID on its own subnet (192.168.2.0/24) and
    # firewall zone for printers and smart-home gear. The isolation is
    # asymmetric and enforced by the firewall:
    #   - lan  -> iot : ALLOWED (your machines can reach printers/sensors)
    #   - iot  -> lan : BLOCKED (a compromised IoT device can't reach the LAN;
    #                   replies to lan-initiated flows still work via conntrack)
    #   - iot  -> wan : ALLOWED (IoT devices can reach the internet)
    # The iot zone's input is REJECTed too, so IoT clients can't hit the
    # router's own admin services (SSH/LuCI) -- only DHCP + DNS are opened.
    echo "  Configuring segregated IoT network"

    # L2: a dedicated bridge so the IoT APs on both radios share one segment.
    ssh "$ROUTER" '
        uci set network.iot_dev=device
        uci set network.iot_dev.type="bridge"
        uci set network.iot_dev.name="br-iot"

        uci set network.iot=interface
        uci set network.iot.proto="static"
        uci set network.iot.device="br-iot"
        uci set network.iot.ipaddr="'"$IOT_ROUTER_IP"'"
        uci set network.iot.netmask="255.255.255.0"
    '

    # DHCP server for the IoT subnet (IPv6 disabled to match the rest).
    ssh "$ROUTER" '
        uci set dhcp.iot=dhcp
        uci set dhcp.iot.interface="iot"
        uci set dhcp.iot.start="100"
        uci set dhcp.iot.limit="150"
        uci set dhcp.iot.leasetime="12h"
        uci set dhcp.iot.dhcpv6="disabled"
        uci set dhcp.iot.ra="disabled"
    '

    # Firewall zone + asymmetric forwarding policy.
    ssh "$ROUTER" '
        uci set firewall.iot=zone
        uci set firewall.iot.name="iot"
        uci set firewall.iot.network="iot"
        uci set firewall.iot.input="REJECT"
        uci set firewall.iot.output="ACCEPT"
        uci set firewall.iot.forward="REJECT"

        # Main LAN -> IoT (one-way). No iot->lan forwarding is created, so IoT
        # devices can never initiate connections into the trusted LAN.
        uci set firewall.lan_to_iot=forwarding
        uci set firewall.lan_to_iot.src="lan"
        uci set firewall.lan_to_iot.dest="iot"

        # IoT -> internet.
        uci set firewall.iot_to_wan=forwarding
        uci set firewall.iot_to_wan.src="iot"
        uci set firewall.iot_to_wan.dest="wan"

        # Allow IoT clients to obtain a DHCP lease and resolve DNS from the
        # router (everything else to the router is rejected by input policy).
        uci set firewall.iot_dhcp=rule
        uci set firewall.iot_dhcp.name="Allow-IoT-DHCP"
        uci set firewall.iot_dhcp.src="iot"
        uci set firewall.iot_dhcp.proto="udp"
        uci set firewall.iot_dhcp.dest_port="67"
        uci set firewall.iot_dhcp.target="ACCEPT"

        uci set firewall.iot_dns=rule
        uci set firewall.iot_dns.name="Allow-IoT-DNS"
        uci set firewall.iot_dns.src="iot"
        uci set firewall.iot_dns.proto="tcp udp"
        uci set firewall.iot_dns.dest_port="53"
        uci set firewall.iot_dns.target="ACCEPT"
    '

    # IoT APs on both radios. psk2 == pure WPA2-PSK (no SAE/PMF), the most
    # compatible mode for printers and cheap sensors. Only created when both
    # the SSID and password are provided.
    if [ -n "${ROUTER_IOT_SSID:-}" ] && [ -n "${ROUTER_IOT_WIFI_PASSWORD:-}" ]; then
        echo "  Adding IoT APs (WPA2) on both radios"
        ssh "$ROUTER" "
            uci set wireless.iot_radio0=wifi-iface
            uci set wireless.iot_radio0.device='radio0'
            uci set wireless.iot_radio0.mode='ap'
            uci set wireless.iot_radio0.network='iot'
            uci set wireless.iot_radio0.ssid='$ROUTER_IOT_SSID'
            uci set wireless.iot_radio0.encryption='psk2'
            uci set wireless.iot_radio0.key='$ROUTER_IOT_WIFI_PASSWORD'

            uci set wireless.iot_radio1=wifi-iface
            uci set wireless.iot_radio1.device='radio1'
            uci set wireless.iot_radio1.mode='ap'
            uci set wireless.iot_radio1.network='iot'
            uci set wireless.iot_radio1.ssid='$ROUTER_IOT_SSID'
            uci set wireless.iot_radio1.encryption='psk2'
            uci set wireless.iot_radio1.key='$ROUTER_IOT_WIFI_PASSWORD'
        "
    else
        echo "  (skipping IoT radios: set ROUTER_IOT_SSID and ROUTER_IOT_WIFI_PASSWORD to enable)"
    fi

    # === Guest network =====================================================
    # A separate SSID on its own subnet (192.168.3.0/24) and firewall zone for
    # visitors. Unlike the IoT zone, isolation is symmetric: there is NO
    # forwarding between guest and lan in EITHER direction. Guests get the
    # internet and nothing else:
    #   - guest -> wan : ALLOWED
    #   - guest -> lan : BLOCKED (no forwarding rule; also covers iot etc.)
    #   - lan   -> guest: BLOCKED (no forwarding rule)
    # The guest zone's input is REJECTed too, so guests can't reach the
    # router's own admin services -- only DHCP + DNS are opened.
    echo "  Configuring guest network"

    # L2: a dedicated bridge so the guest APs on both radios share one segment.
    ssh "$ROUTER" '
        uci set network.guest_dev=device
        uci set network.guest_dev.type="bridge"
        uci set network.guest_dev.name="br-guest"

        uci set network.guest=interface
        uci set network.guest.proto="static"
        uci set network.guest.device="br-guest"
        uci set network.guest.ipaddr="'"$GUEST_ROUTER_IP"'"
        uci set network.guest.netmask="255.255.255.0"
    '

    # DHCP server for the guest subnet (IPv6 disabled to match the rest).
    ssh "$ROUTER" '
        uci set dhcp.guest=dhcp
        uci set dhcp.guest.interface="guest"
        uci set dhcp.guest.start="100"
        uci set dhcp.guest.limit="150"
        uci set dhcp.guest.leasetime="12h"
        uci set dhcp.guest.dhcpv6="disabled"
        uci set dhcp.guest.ra="disabled"
    '

    # Firewall zone: WAN-only. No lan<->guest forwarding is created in either
    # direction, so the guest segment is fully isolated from the trusted LAN.
    ssh "$ROUTER" '
        uci set firewall.guest=zone
        uci set firewall.guest.name="guest"
        uci set firewall.guest.network="guest"
        uci set firewall.guest.input="REJECT"
        uci set firewall.guest.output="ACCEPT"
        uci set firewall.guest.forward="REJECT"

        # Guest -> internet (the only permitted forwarding).
        uci set firewall.guest_to_wan=forwarding
        uci set firewall.guest_to_wan.src="guest"
        uci set firewall.guest_to_wan.dest="wan"

        # Allow guests to obtain a DHCP lease and resolve DNS from the router
        # (everything else to the router is rejected by the input policy).
        uci set firewall.guest_dhcp=rule
        uci set firewall.guest_dhcp.name="Allow-Guest-DHCP"
        uci set firewall.guest_dhcp.src="guest"
        uci set firewall.guest_dhcp.proto="udp"
        uci set firewall.guest_dhcp.dest_port="67"
        uci set firewall.guest_dhcp.target="ACCEPT"

        uci set firewall.guest_dns=rule
        uci set firewall.guest_dns.name="Allow-Guest-DNS"
        uci set firewall.guest_dns.src="guest"
        uci set firewall.guest_dns.proto="tcp udp"
        uci set firewall.guest_dns.dest_port="53"
        uci set firewall.guest_dns.target="ACCEPT"
    '

    # Guest APs on both radios. Only created when both the SSID and password
    # are provided.
    if [ -n "${ROUTER_GUEST_SSID:-}" ] && [ -n "${ROUTER_GUEST_WIFI_PASSWORD:-}" ]; then
        echo "  Adding guest APs on both radios"
        ssh "$ROUTER" "
            uci set wireless.guest_radio0=wifi-iface
            uci set wireless.guest_radio0.device='radio0'
            uci set wireless.guest_radio0.mode='ap'
            uci set wireless.guest_radio0.network='guest'
            uci set wireless.guest_radio0.ssid='$ROUTER_GUEST_SSID'
            uci set wireless.guest_radio0.encryption='sae-mixed'
            uci set wireless.guest_radio0.key='$ROUTER_GUEST_WIFI_PASSWORD'

            uci set wireless.guest_radio1=wifi-iface
            uci set wireless.guest_radio1.device='radio1'
            uci set wireless.guest_radio1.mode='ap'
            uci set wireless.guest_radio1.network='guest'
            uci set wireless.guest_radio1.ssid='$ROUTER_GUEST_SSID'
            uci set wireless.guest_radio1.encryption='sae-mixed'
            uci set wireless.guest_radio1.key='$ROUTER_GUEST_WIFI_PASSWORD'
        "
    else
        echo "  (skipping guest radios: set ROUTER_GUEST_SSID and ROUTER_GUEST_WIFI_PASSWORD to enable)"
    fi

    # Static DHCP lease for the printer on the IoT subnet. Because mDNS/Bonjour
    # discovery doesn't cross subnets, a fixed address lets LAN machines add
    # the printer by IP (192.168.2.10) and always find it.
    if [ -n "${ROUTER_PRINTER_MAC:-}" ]; then
        echo "  Setting printer static lease (IoT)"
        ssh "$ROUTER" "
            uci set dhcp.printer=host
            uci set dhcp.printer.name='printer'
            uci set dhcp.printer.mac='$ROUTER_PRINTER_MAC'
            uci set dhcp.printer.ip='$PRINTER_STATIC_IP'
        "
    fi

    # Static DHCP lease for mini
    if [ -n "${ROUTER_MINI_MAC:-}" ]; then
        echo "  Setting mini static lease"
        ssh "$ROUTER" "
            uci set dhcp.mini=host
            uci set dhcp.mini.name='mini'
            uci set dhcp.mini.mac='$ROUTER_MINI_MAC'
            uci set dhcp.mini.ip='$MINI_STATIC_IP'
        "
    fi

    # Static DHCP lease for the MikroTik cAP access point, so deploy_ap.sh
    # always finds it at a predictable address.
    if [ -n "${ROUTER_AP_MAC:-}" ]; then
        echo "  Setting cAP access point static lease"
        ssh "$ROUTER" "
            uci set dhcp.cap_ap=host
            uci set dhcp.cap_ap.name='cap-ap'
            uci set dhcp.cap_ap.mac='$ROUTER_AP_MAC'
            uci set dhcp.cap_ap.ip='$AP_STATIC_IP'
        "
    fi

    # Forward DNS to AdGuard Home on the mini, with 1.1.1.1 as a fallback for
    # when AdGuard is unavailable. noresolv=1 ignores the ISP-provided resolvers.
    if [ -n "${ROUTER_MINI_MAC:-}" ]; then
        echo "  Forwarding DNS to AdGuard Home"
        ssh "$ROUTER" '
            uci set dhcp.@dnsmasq[0].noresolv="1"
            uci del_list dhcp.@dnsmasq[0].server="'"$MINI_STATIC_IP"'" 2>/dev/null || true
            uci add_list dhcp.@dnsmasq[0].server="'"$MINI_STATIC_IP"'"
            uci del_list dhcp.@dnsmasq[0].server="1.1.1.1" 2>/dev/null || true
            uci add_list dhcp.@dnsmasq[0].server="1.1.1.1"
        '
    fi

    # Service domains: resolve to the mini, where a Caddy reverse proxy
    # (nixos/server/reverse-proxy.nix) routes each hostname to the right port.
    # dnsmasq answers these locally; .lan is its local domain so they are
    # never forwarded upstream.
    echo "  Setting service domain DNS entries"
    for domain in home.lan media.lan; do
        ssh "$ROUTER" '
            uci del_list dhcp.@dnsmasq[0].address="/'"$domain"'/'"$MINI_STATIC_IP"'" 2>/dev/null || true
            uci add_list dhcp.@dnsmasq[0].address="/'"$domain"'/'"$MINI_STATIC_IP"'"
        '
    done

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

    # Static DHCP lease for the Windows PC (Sunshine game-streaming host), so
    # Moonlight clients always find it at a predictable address.
    if [ -n "${ROUTER_WINDOWS_PC_MAC:-}" ]; then
        echo "  Setting Windows PC static lease"
        ssh "$ROUTER" "
            uci set dhcp.windows_pc=host
            uci set dhcp.windows_pc.name='camerons-pc'
            uci set dhcp.windows_pc.mac='$ROUTER_WINDOWS_PC_MAC'
            uci set dhcp.windows_pc.ip='$WINDOWS_PC_STATIC_IP'
        "
    fi

    if [ -n "${ROUTER_AIR1_MAC:-}" ]; then
        echo "  Setting Apollo AIR-1 static lease"
        ssh "$ROUTER" "
            uci set dhcp.air1=host
            uci set dhcp.air1.name='apollo-air-1'
            uci set dhcp.air1.mac='$ROUTER_AIR1_MAC'
            uci set dhcp.air1.ip='$AIR1_STATIC_IP'
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

    # Root password = LuCI web UI login + SSH password auth. Unlike the uci
    # settings above, passwd takes effect immediately (it is not staged/committed).
    if [ -n "${ROUTER_PASSWORD:-}" ]; then
        echo "  Setting router (LuCI/SSH) password"
        ssh "$ROUTER" "printf '%s\n%s\n' '$ROUTER_PASSWORD' '$ROUTER_PASSWORD' | passwd root"
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
    local reboot=1
    for arg in "$@"; do
        case "$arg" in
            --no-reboot) reboot=0 ;;
            *) echo "Unknown apply option: $arg" >&2; exit 1 ;;
        esac
    done

    echo "=== Committing ==="
    ssh "$ROUTER" '
        uci commit dhcp
        uci commit firewall
        uci commit network
        uci commit sqm
        uci commit system
        uci commit wireless
    '

    if [ "$reboot" -eq 1 ]; then
        echo "=== Rebooting ==="
        ssh "$ROUTER" "reboot"
        echo "Router is rebooting. It should be back in about a minute."
        return
    fi

    # --no-reboot: apply the committed config by reloading each service instead
    # of rebooting. Ordered least-disruptive first; network/wifi come last
    # because they can briefly drop the link (and your SSH session) as they
    # re-apply -- by then every other reload has already run. dnsmasq is
    # restarted (not reloaded) so new static DHCP leases take effect cleanly.
    echo "=== Reloading services (no reboot) ==="
    ssh "$ROUTER" '
        /etc/init.d/system reload
        /etc/init.d/firewall reload
        /etc/init.d/dnsmasq restart
        /etc/init.d/sqm restart
        /etc/init.d/network reload
        wifi reload
    '
    echo "Services reloaded (no reboot performed)."
}

case "${1:-}" in
    install) do_install ;;
    set)     do_set ;;
    apply)   shift; do_apply "$@" ;;
    changes) ssh "$ROUTER" "uci changes" ;;
    *)
        echo "Usage: ./deploy.sh <install|set|apply [--no-reboot]|changes>" >&2
        exit 1
        ;;
esac
