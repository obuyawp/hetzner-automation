#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

: "${NETBIRD_SETUP_KEY:?Set NETBIRD_SETUP_KEY}"
NETBIRD_MGMT_URL="${NETBIRD_MGMT_URL:-https://ngao.oneacrefund.org}"

if ! command -v netbird >/dev/null 2>&1; then
  echo "netbird binary not found. Install NetBird first." >&2
  exit 1
fi

netbird up --setup-key "${NETBIRD_SETUP_KEY}" --management-url "${NETBIRD_MGMT_URL}"

echo "NetBird enrollment complete."
