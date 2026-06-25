#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

: "${TENABLE_KEY:?Set TENABLE_KEY}"
TENABLE_GROUPS="${TENABLE_GROUPS:-Linux-Servers}"
TENABLE_INSTALL_TIMEOUT_SECONDS="${TENABLE_INSTALL_TIMEOUT_SECONDS:-240}"
TENABLE_REQUIRED="${TENABLE_REQUIRED:-false}"
TENABLE_INSTALLER_URL="https://sensor.cloud.tenable.com/install/agent?groups=${TENABLE_GROUPS}"
TENABLE_INSTALL_SCRIPT="/tmp/tenable_agent_install.sh"
TENABLE_INSTALL_LOG="/tmp/tenable_agent_install.log"

curl -fsSL -H "X-Key: ${TENABLE_KEY}" "${TENABLE_INSTALLER_URL}" -o "${TENABLE_INSTALL_SCRIPT}"
chmod +x "${TENABLE_INSTALL_SCRIPT}"

set +e
if command -v timeout >/dev/null 2>&1; then
  timeout "${TENABLE_INSTALL_TIMEOUT_SECONDS}s" bash "${TENABLE_INSTALL_SCRIPT}" 2>&1 | tee "${TENABLE_INSTALL_LOG}"
  INSTALL_RC=${PIPESTATUS[0]}
else
  bash "${TENABLE_INSTALL_SCRIPT}" 2>&1 | tee "${TENABLE_INSTALL_LOG}"
  INSTALL_RC=${PIPESTATUS[0]}
fi
set -e

if [[ "${INSTALL_RC}" -eq 124 ]]; then
  echo "Tenable install timed out after ${TENABLE_INSTALL_TIMEOUT_SECONDS}s. Check ${TENABLE_INSTALL_LOG}." >&2
  if [[ "${TENABLE_REQUIRED}" == "true" ]]; then
    exit 1
  fi
  echo "Continuing because TENABLE_REQUIRED=false." >&2
  exit 0
fi

if [[ "${INSTALL_RC}" -ne 0 ]]; then
  echo "Tenable install failed (exit ${INSTALL_RC}). Check ${TENABLE_INSTALL_LOG}." >&2
  if [[ "${TENABLE_REQUIRED}" == "true" ]]; then
    exit "${INSTALL_RC}"
  fi
  echo "Continuing because TENABLE_REQUIRED=false." >&2
  exit 0
fi

echo "Tenable agent installation completed."
