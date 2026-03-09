#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

: "${TENABLE_KEY:?Set TENABLE_KEY}"
TENABLE_GROUPS="${TENABLE_GROUPS:-Linux-Servers}"

curl -fsSL -H "X-Key: ${TENABLE_KEY}" \
  "https://sensor.cloud.tenable.com/install/agent?groups=${TENABLE_GROUPS}" | bash

echo "Tenable agent installation command executed."
