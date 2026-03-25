#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/backstage"
BACKSTAGE_HOME="${BACKSTAGE_HOME:-/opt/backstage}"

usage() {
  cat <<'EOF'
Usage:
  sudo ./backstage/deploy_backstage.sh <command>

Commands:
  bootstrap   Copy compose/env/nginx templates into BACKSTAGE_HOME.
  sync        Overwrite compose/nginx templates in BACKSTAGE_HOME from repo.
  up          Bootstrap and start Backstage stack.
  pull        Pull latest images.
  restart     Restart Backstage stack.
  logs        Tail Backstage logs.
  ps          Show stack status.
  down        Stop stack.

Environment:
  BACKSTAGE_HOME   Target deploy directory (default: /opt/backstage)
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_docker_compose() {
  require_cmd docker
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose plugin is required (docker compose)." >&2
    exit 1
  fi
}

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [ -e "$dest" ]; then
    echo "Keeping existing file: $dest"
    return
  fi
  cp "$src" "$dest"
  echo "Created: $dest"
}

copy_force() {
  local src="$1"
  local dest="$2"
  cp "$src" "$dest"
  echo "Updated: $dest"
}

bootstrap() {
  mkdir -p "$BACKSTAGE_HOME"

  copy_if_missing "${TEMPLATE_DIR}/docker-compose.yml" "${BACKSTAGE_HOME}/docker-compose.yml"
  copy_if_missing "${TEMPLATE_DIR}/.env.example" "${BACKSTAGE_HOME}/.env"
  copy_if_missing "${TEMPLATE_DIR}/nginx-backstage.conf.example" "${BACKSTAGE_HOME}/nginx-backstage.conf"
  copy_if_missing "${TEMPLATE_DIR}/app-config.production.yaml" "${BACKSTAGE_HOME}/app-config.production.yaml"

  echo
  echo "Bootstrap complete."
  echo "Review and edit: ${BACKSTAGE_HOME}/.env"
  echo "Then start with:  sudo ${BASH_SOURCE[0]} up"
}

sync_templates() {
  mkdir -p "$BACKSTAGE_HOME"
  copy_force "${TEMPLATE_DIR}/docker-compose.yml" "${BACKSTAGE_HOME}/docker-compose.yml"
  copy_force "${TEMPLATE_DIR}/nginx-backstage.conf.example" "${BACKSTAGE_HOME}/nginx-backstage.conf"
  copy_force "${TEMPLATE_DIR}/app-config.production.yaml" "${BACKSTAGE_HOME}/app-config.production.yaml"
  echo
  echo "Sync complete."
  echo "Review and edit env if needed: ${BACKSTAGE_HOME}/.env"
}

compose_cmd() {
  docker compose \
    --project-name backstage \
    --env-file "${BACKSTAGE_HOME}/.env" \
    -f "${BACKSTAGE_HOME}/docker-compose.yml" \
    "$@"
}

command="${1:-}"
if [ -z "$command" ]; then
  usage >&2
  exit 1
fi

case "$command" in
  bootstrap)
    bootstrap
    ;;
  up)
    require_docker_compose
    bootstrap
    compose_cmd up -d
    ;;
  sync)
    sync_templates
    ;;
  pull)
    require_docker_compose
    compose_cmd pull
    ;;
  restart)
    require_docker_compose
    compose_cmd restart
    ;;
  logs)
    require_docker_compose
    compose_cmd logs -f backstage
    ;;
  ps)
    require_docker_compose
    compose_cmd ps
    ;;
  down)
    require_docker_compose
    compose_cmd down
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 1
    ;;
esac
