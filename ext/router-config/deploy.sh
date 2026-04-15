#!/usr/bin/env bash
# Deploy router configuration to the Flint 2
# Usage: ./deploy.sh [router_ip]

set -euo pipefail

ROUTER_IP="${1:-192.168.1.1}"
ROUTER="root@${ROUTER_IP}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying to ${ROUTER}..."
scp "${SCRIPT_DIR}/configure.sh" "${ROUTER}":/tmp/configure.sh
ssh "${ROUTER}" "sh /tmp/configure.sh"
echo "Deployment complete."
