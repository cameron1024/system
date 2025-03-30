#! /usr/bin/env bash

set -euo pipefail

# env vars are added in nix config
curl -o- https://puro.dev/install.sh | PURO_VERSION="1.4.8" bash
