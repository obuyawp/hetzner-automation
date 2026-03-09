#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

SERVER_ACTIVE="${ZABBIX_SERVER_ACTIVE:-94.130.79.32,zabbixdata.oneacrefund.org}"
AGENT_CONF=""

install_zabbix_agent_if_missing() {
  if [[ -f /etc/zabbix/zabbix_agent2.conf || -f /etc/zabbix/zabbix_agentd.conf ]]; then
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    if ! DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent2; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent
    fi
    return 0
  fi

  echo "Zabbix agent config not found and automatic install is unsupported on this OS." >&2
  return 1
}

install_zabbix_agent_if_missing

if [[ -f /etc/zabbix/zabbix_agent2.conf ]]; then
  AGENT_CONF="/etc/zabbix/zabbix_agent2.conf"
elif [[ -f /etc/zabbix/zabbix_agentd.conf ]]; then
  AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
else
  echo "Zabbix agent config not found after install attempt." >&2
  exit 1
fi

if grep -q "^ServerActive=" "${AGENT_CONF}"; then
  sed -i "s|^ServerActive=.*|ServerActive=${SERVER_ACTIVE}|" "${AGENT_CONF}"
else
  echo "ServerActive=${SERVER_ACTIVE}" >>"${AGENT_CONF}"
fi

systemctl restart zabbix-agent2 2>/dev/null || systemctl restart zabbix-agent || true
systemctl enable zabbix-agent2 2>/dev/null || systemctl enable zabbix-agent || true

echo "Zabbix ServerActive configured: ${SERVER_ACTIVE}"
