#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

WAZUH_MANAGER="${WAZUH_MANAGER:-65.109.134.247}"
WAZUH_AGENT_GROUP="${WAZUH_AGENT_GROUP:-Linux_Servers}"
WAZUH_DEB_URL="${WAZUH_DEB_URL:-https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.1-1_amd64.deb}"
WAZUH_DEB_FILE="${WAZUH_DEB_FILE:-/tmp/wazuh-agent_4.14.1-1_amd64.deb}"
AUDIT_RULES_FILE="/etc/audit/rules.d/audit.rules"

if ! dpkg -s wazuh-agent >/dev/null 2>&1; then
  wget -qO "${WAZUH_DEB_FILE}" "${WAZUH_DEB_URL}"
  WAZUH_MANAGER="${WAZUH_MANAGER}" WAZUH_AGENT_GROUP="${WAZUH_AGENT_GROUP}" dpkg -i "${WAZUH_DEB_FILE}"
fi

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

apt-get update -y
apt-get install -y auditd
systemctl enable auditd
systemctl start auditd

RULES=(
  "-a exit,always -F auid=1000 -F egid!=994 -F auid!=-1 -F arch=b32 -S execve -k audit-wazuh-c"
  "-a exit,always -F auid=1000 -F egid!=994 -F auid!=-1 -F arch=b64 -S execve -k audit-wazuh-c"
  "-a exit,always -F arch=b64 -F euid=0 -S execve -k audit-wazuh-c"
  "-a exit,always -F arch=b32 -F euid=0 -S execve -k audit-wazuh-c"
)

for rule in "${RULES[@]}"; do
  if ! grep -Fqx "${rule}" "${AUDIT_RULES_FILE}"; then
    echo "${rule}" >>"${AUDIT_RULES_FILE}"
  fi
done

auditctl -R "${AUDIT_RULES_FILE}"
auditctl -l
systemctl restart wazuh-agent

echo "Wazuh agent installed and audit rules applied."
