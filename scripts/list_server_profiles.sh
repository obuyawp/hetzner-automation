#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/list_server_profiles.sh [--markdown] [profile_file]

Examples:
  ./scripts/list_server_profiles.sh
  ./scripts/list_server_profiles.sh --markdown
  ./scripts/list_server_profiles.sh ./server_profiles.auto.tfvars.json
EOF
}

markdown=false
profile_file="server_profiles.auto.tfvars.json"
profile_file_set=false

for arg in "$@"; do
  case "$arg" in
    --markdown)
      markdown=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ "$profile_file_set" = false ]; then
        profile_file="$arg"
        profile_file_set=true
      else
        echo "Unexpected argument: $arg" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [ ! -f "$profile_file" ]; then
  echo "Profile file not found: $profile_file" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to render the profile table. Please install jq and try again." >&2
  exit 1
fi

if [ "$markdown" = true ]; then
  {
    echo "| Profile | Category | Arch | vCPU | RAM (GB) | Disk (GB) | Traffic (TB) | Hourly (EUR) | Monthly (EUR) |"
    echo "|---|---|---|---:|---:|---:|---:|---:|---:|"
    jq -r '
      .server_profiles
      | to_entries
      | sort_by(.value.monthly_eur)
      | .[]
      | "| \(.key) | \(.value.category) | \(.value.architecture) | \(.value.vcpu) | \(.value.ram_gb) | \(.value.disk_gb) | \(.value.traffic_tb) | \(.value.hourly_eur) | \(.value.monthly_eur) |"
    ' "$profile_file"
  }
  exit 0
fi

{
  echo -e "PROFILE\tCATEGORY\tARCH\tVCPU\tRAM_GB\tDISK_GB\tTRAFFIC_TB\tHOURLY_EUR\tMONTHLY_EUR"
  jq -r '
    .server_profiles
    | to_entries
    | sort_by(.value.monthly_eur)
    | .[]
    | "\(.key)\t\(.value.category)\t\(.value.architecture)\t\(.value.vcpu)\t\(.value.ram_gb)\t\(.value.disk_gb)\t\(.value.traffic_tb)\t\(.value.hourly_eur)\t\(.value.monthly_eur)"
  ' "$profile_file"
} | if command -v column >/dev/null 2>&1; then
  column -t -s $'\t'
else
  cat
fi
