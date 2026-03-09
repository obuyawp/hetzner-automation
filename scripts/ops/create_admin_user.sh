#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root (or with sudo)." >&2
  exit 1
fi

USERNAME="${1:-}"
PASSWORD="${2:-}"

if [[ -z "${USERNAME}" || -z "${PASSWORD}" ]]; then
  echo "Usage: $0 <username> <password>" >&2
  exit 1
fi

if id "${USERNAME}" >/dev/null 2>&1; then
  echo "User ${USERNAME} already exists. Updating password and sudo access."
else
  useradd -m -s /bin/bash "${USERNAME}"
fi

echo "${USERNAME}:${PASSWORD}" | chpasswd
usermod -aG sudo "${USERNAME}"

cat >"/etc/sudoers.d/${USERNAME}" <<EOF
${USERNAME} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 "/etc/sudoers.d/${USERNAME}"

echo "User ${USERNAME} is ready with sudo access."
