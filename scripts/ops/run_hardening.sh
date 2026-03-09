#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

HARDENING_SCRIPT="${HARDENING_SCRIPT:-${SCRIPT_DIR}/CIS_Ubuntu_Hardening_Benchmarks.sh}"

if [[ ! -f "${HARDENING_SCRIPT}" ]]; then
  echo "Hardening script not found at ${HARDENING_SCRIPT}" >&2
  exit 1
fi

chmod +x "${HARDENING_SCRIPT}"
bash "${HARDENING_SCRIPT}"

echo "Hardening script executed. Reboot is recommended."
