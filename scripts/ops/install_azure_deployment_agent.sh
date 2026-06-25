#!/usr/bin/env bash
set -euo pipefail

AZP_TOKEN="${AZP_TOKEN:-${AZURE_DEVOPS_PAT:-}}"
if [[ -z "${AZP_TOKEN}" ]]; then
  echo "AZP_TOKEN is required to configure Azure deployment agent non-interactively." >&2
  exit 1
fi

AGENT_DIR="${HOME}/azagent"
mkdir -p "${AGENT_DIR}"
cd "${AGENT_DIR}"
curl -fkSL -o vstsagent.tar.gz https://download.agent.dev.azure.com/agent/4.269.0/vsts-agent-linux-x64-4.269.0.tar.gz
tar -zxvf vstsagent.tar.gz

if [ -x "$(command -v systemctl)" ]; then
  ./config.sh \
    --deploymentgroup \
    --deploymentgroupname "all-linux-servers" \
    --acceptteeeula \
    --agent "$HOSTNAME" \
    --url https://dev.azure.com/OAFDev/ \
    --work _work \
    --projectname 'prd-pipelines' \
    --auth pat \
    --token "${AZP_TOKEN}" \
    --runasservice \
    --replace \
    --unattended
  sudo ./svc.sh install
  sudo ./svc.sh start
else
  ./config.sh \
    --deploymentgroup \
    --deploymentgroupname "all-linux-servers" \
    --acceptteeeula \
    --agent "$HOSTNAME" \
    --url https://dev.azure.com/OAFDev/ \
    --work _work \
    --projectname 'prd-pipelines' \
    --auth pat \
    --token "${AZP_TOKEN}" \
    --replace \
    --unattended
  ./run.sh
fi
