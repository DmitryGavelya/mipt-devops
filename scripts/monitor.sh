#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s SERVICE [SYSLOG_FILE]\n' "$0" >&2
}

service_name=${1:-}
syslog_file=${2:-/var/log/syslog}
if [[ -z "$service_name" ]]; then
  usage
  exit 64
fi

if ! command -v systemctl >/dev/null 2>&1; then
  printf 'ERROR: systemctl is not available\n' >&2
  exit 69
fi

if systemctl is-active --quiet "$service_name"; then
  printf 'service=%s status=active\n' "$service_name"
else
  status=$?
  printf 'service=%s status=inactive\n' "$service_name"
  if command -v journalctl >/dev/null 2>&1; then
    journalctl -u "$service_name" -n 10 --no-pager || true
  fi
  exit "$status"
fi

if [[ -r "$syslog_file" ]]; then
  prefixes=()
  for minute_offset in $(seq 0 60); do
    if prefix=$(date -d "-${minute_offset} minutes" '+%b %e %H:%M' 2>/dev/null); then
      prefixes+=("$prefix")
    else
      prefixes+=("$(date -v-${minute_offset}M '+%b %e %H:%M')")
    fi
  done
  prefix_pattern=$(IFS='|'; printf '%s' "${prefixes[*]}")
  errors=$(
    grep -E -i "^(${prefix_pattern}).*(error|err|critical|crit|failed|failure)" "$syslog_file" |
      awk 'END { print NR + 0 }' || true
  )
  printf 'syslog_errors_last_hour=%s file=%s\n' "$errors" "$syslog_file"
else
  printf 'syslog_errors_last_hour=unavailable file=%s\n' "$syslog_file"
fi
