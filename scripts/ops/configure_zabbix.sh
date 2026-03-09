#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

SERVER_ACTIVE="${ZABBIX_SERVER_ACTIVE:-94.130.79.32,zabbixdata.oneacrefund.org}"
AGENT_CONF=""

if [[ -f /etc/zabbix/zabbix_agent2.conf ]]; then
  AGENT_CONF="/etc/zabbix/zabbix_agent2.conf"
elif [[ -f /etc/zabbix/zabbix_agentd.conf ]]; then
  AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
else
  echo "Zabbix agent config not found. Install zabbix-agent first." >&2
  exit 1
fi

if grep -q "^ServerActive=" "${AGENT_CONF}"; then
  sed -i "s|^ServerActive=.*|ServerActive=${SERVER_ACTIVE}|" "${AGENT_CONF}"
else
  echo "ServerActive=${SERVER_ACTIVE}" >>"${AGENT_CONF}"
fi

systemctl restart zabbix-agent2 2>/dev/null || systemctl restart zabbix-agent || true

echo "Zabbix ServerActive configured: ${SERVER_ACTIVE}"
