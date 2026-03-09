#!/usr/bin/env bash
set -euo pipefail

mkdir azagent
cd azagent
curl -fkSL -o vstsagent.tar.gz https://download.agent.dev.azure.com/agent/4.269.0/vsts-agent-linux-x64-4.269.0.tar.gz
tar -zxvf vstsagent.tar.gz

if [ -x "$(command -v systemctl)" ]; then
  ./config.sh --deploymentgroup --deploymentgroupname "all-linux-servers" --acceptteeeula --agent "$HOSTNAME" --url https://dev.azure.com/OAFDev/ --work _work --projectname 'prd-pipelines' --runasservice
  sudo ./svc.sh install
  sudo ./svc.sh start
else
  ./config.sh --deploymentgroup --deploymentgroupname "all-linux-servers" --acceptteeeula --agent "$HOSTNAME" --url https://dev.azure.com/OAFDev/ --work _work --projectname 'prd-pipelines'
  ./run.sh
fi
