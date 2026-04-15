#!/bin/sh
# OpenWrt configuration for GL.iNet Flint 2 (GL-MT6000)
# Apply with: scp configure.sh root@192.168.1.1:/tmp/ && ssh root@192.168.1.1 sh /tmp/configure.sh

set -e

echo "=== Applying system settings ==="
uci set system.@system[0].hostname='router'
uci set system.@system[0].timezone='GMT0BST,M3.5.0/1,M10.5.0'
uci set system.@system[0].zonename='Europe/London'
uci commit system

echo "=== Applying wireless settings ==="

# -- 2.4 GHz radio --
uci set wireless.radio0.country='GB'
uci set wireless.radio0.disabled='0'

# SSID and password are set manually (not stored in version control)
uci set wireless.default_radio0.encryption='sae-mixed'  # WPA2-PSK + WPA3-SAE

# -- 5 GHz radio --
uci set wireless.radio1.country='GB'
uci set wireless.radio1.channel='36'
uci set wireless.radio1.htmode='HE160'  # 160 MHz channel width
uci set wireless.radio1.disabled='0'

# SSID and password are set manually (not stored in version control)
uci set wireless.default_radio1.encryption='sae-mixed'  # WPA2-PSK + WPA3-SAE

uci commit wireless

echo "=== Applying SQM settings ==="

# Create SQM queue if it doesn't exist
if ! uci -q get sqm.wan > /dev/null; then
    uci set sqm.wan=queue
fi

uci set sqm.wan.enabled='1'
uci set sqm.wan.interface='wan'
uci set sqm.wan.qdisc='cake'
uci set sqm.wan.script='piece_of_cake.qos'

# Set to ~85% of your actual speeds in Kbit/s
# Adjust these after running a bufferbloat test at waveform.com/tools/bufferbloat
uci set sqm.wan.download='42500'   # ~85% of 50 Mbps - ADJUST TO YOUR ACTUAL SPEED
uci set sqm.wan.upload='8500'      # ~85% of 10 Mbps - ADJUST TO YOUR ACTUAL SPEED

uci set sqm.wan.linklayer='ethernet'
uci set sqm.wan.overhead='44'
uci commit sqm

echo "=== Applying firewall settings ==="

# Disable flow offloading (incompatible with SQM)
uci set firewall.@defaults[0].flow_offloading='0'
uci set firewall.@defaults[0].flow_offloading_hw='0'
uci commit firewall

echo "=== Reloading configuration ==="
reload_config

# Restart specific services that need it
/etc/init.d/network restart
/etc/init.d/sqm restart

echo "=== Done ==="
