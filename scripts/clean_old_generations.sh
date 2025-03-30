#! /usr/bin/env bash
set -euxo pipefail

nix-collect-garbage --delete-older-than 14d
sudo /run/current-system/bin/switch-to-configuration boot
