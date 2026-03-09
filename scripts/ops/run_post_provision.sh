#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${RUN_CREATE_USER:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/create_admin_user.sh" "${ADMIN_USERNAME:?Set ADMIN_USERNAME}" "${ADMIN_PASSWORD:?Set ADMIN_PASSWORD}"
fi

if [[ "${RUN_AZURE_AGENT:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/install_azure_deployment_agent.sh"
fi

if [[ "${RUN_ZABBIX:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/configure_zabbix.sh"
fi

if [[ "${RUN_NETBIRD:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/install_netbird.sh"
fi

if [[ "${RUN_WAZUH:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/install_wazuh.sh"
fi

if [[ "${RUN_TENABLE:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/install_tenable.sh"
fi

if [[ "${RUN_HARDENING:-false}" == "true" ]]; then
  "${SCRIPT_DIR}/run_hardening.sh"
fi

echo "Post-provision script execution completed."
