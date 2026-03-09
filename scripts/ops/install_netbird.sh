#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

: "${NETBIRD_SETUP_KEY:?Set NETBIRD_SETUP_KEY}"
NETBIRD_MGMT_URL="${NETBIRD_MGMT_URL:-https://ngao.oneacrefund.org:33073}"
NETBIRD_UP_RETRIES="${NETBIRD_UP_RETRIES:-5}"
NETBIRD_UP_RETRY_DELAY="${NETBIRD_UP_RETRY_DELAY:-15}"
NETBIRD_DAEMON_WAIT_SECONDS="${NETBIRD_DAEMON_WAIT_SECONDS:-30}"

install_netbird_if_missing() {
  if command -v netbird >/dev/null 2>&1; then
    return 0
  fi

  DEBIAN_FRONTEND=noninteractive curl -fsSL https://pkgs.netbird.io/install.sh | bash
}

ensure_netbird_service_running() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable --now netbird || true
  fi
}

wait_for_netbird_daemon() {
  local waited=0
  while (( waited < NETBIRD_DAEMON_WAIT_SECONDS )); do
    if netbird status >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

enroll_with_retries() {
  local attempt=1
  local err_file
  err_file="$(mktemp)"

  while (( attempt <= NETBIRD_UP_RETRIES )); do
    if netbird up --setup-key "${NETBIRD_SETUP_KEY}" --management-url "${NETBIRD_MGMT_URL}" >"${err_file}" 2>&1; then
      rm -f "${err_file}"
      return 0
    fi

    echo "NetBird enrollment attempt ${attempt}/${NETBIRD_UP_RETRIES} failed." >&2
    sed -n '1,8p' "${err_file}" >&2 || true

    if (( attempt == NETBIRD_UP_RETRIES )); then
      echo "NetBird enrollment failed after ${NETBIRD_UP_RETRIES} attempts. Verify NETBIRD_MGMT_URL/DNS/firewall reachability from this host." >&2
      rm -f "${err_file}"
      return 1
    fi

    sleep "${NETBIRD_UP_RETRY_DELAY}"
    attempt=$((attempt + 1))
  done
}

install_netbird_if_missing

if ! command -v netbird >/dev/null 2>&1; then
  echo "netbird binary not found after install attempt." >&2
  exit 1
fi

ensure_netbird_service_running
wait_for_netbird_daemon || true
enroll_with_retries

echo "NetBird enrollment complete."
