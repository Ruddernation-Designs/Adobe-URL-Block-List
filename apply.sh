#!/usr/bin/env bash
# Applies the Adobe blocklist to the system hosts file on macOS and Linux.
#
# The records are wrapped in marker comments so re-running this script
# replaces the previous block instead of appending duplicates, and so
# revert.sh can remove them cleanly.
#
# Usage: sudo ./apply.sh
set -euo pipefail

START_MARKER="## ADOBE_BLOCKLIST_START ##"
END_MARKER="## ADOBE_BLOCKLIST_END ##"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADOBE_HOSTS_FILE="$SCRIPT_DIR/hosts"
BACKUP_HOSTS_FILE="$SCRIPT_DIR/hosts.bak"
# Overridable so the scripts can be tested without touching the real hosts file
SYS_HOSTS_FILE="${ADOBE_BLOCKLIST_HOSTS_FILE:-/etc/hosts}"

main() {
  check_preconditions
  create_backup
  remove_existing_block
  append_block
  flush_dns_cache
  echo "Applied $(record_count) records to $SYS_HOSTS_FILE"
}

check_preconditions() {
  if [[ ! -f "$ADOBE_HOSTS_FILE" ]]; then
    echo "Blocklist file not found at $ADOBE_HOSTS_FILE" >&2
    exit 1
  fi

  if [[ ! -w "$SYS_HOSTS_FILE" ]]; then
    echo "Cannot write to $SYS_HOSTS_FILE. Please re-run with sudo: sudo $0" >&2
    exit 1
  fi
}

create_backup() {
  if [[ -f "$BACKUP_HOSTS_FILE" ]]; then
    return
  fi

  cp "$SYS_HOSTS_FILE" "$BACKUP_HOSTS_FILE"
  echo "Created hosts.bak"
}

remove_existing_block() {
  if ! grep -qF "$START_MARKER" "$SYS_HOSTS_FILE"; then
    return
  fi

  local temp_file
  temp_file="$(mktemp)"
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
  ' "$SYS_HOSTS_FILE" > "$temp_file"
  cat "$temp_file" > "$SYS_HOSTS_FILE"
  rm -f "$temp_file"
  echo "Removed previously applied records"
}

append_block() {
  {
    echo "$START_MARKER"
    blocklist_records
    echo "$END_MARKER"
  } >> "$SYS_HOSTS_FILE"
}

blocklist_records() {
  grep -Ev '^[[:space:]]*(#|$)' "$ADOBE_HOSTS_FILE"
}

record_count() {
  blocklist_records | wc -l | tr -d ' '
}

flush_dns_cache() {
  # Skip when targeting a test file rather than the real hosts file
  if [[ "$SYS_HOSTS_FILE" != "/etc/hosts" ]]; then
    return
  fi

  case "$(uname -s)" in
    Darwin)
      dscacheutil -flushcache
      killall -HUP mDNSResponder 2>/dev/null || true
      echo "Flushed DNS cache"
      ;;
    Linux)
      if command -v resolvectl > /dev/null 2>&1; then
        resolvectl flush-caches && echo "Flushed DNS cache" && return
      fi
      if command -v systemd-resolve > /dev/null 2>&1; then
        systemd-resolve --flush-caches && echo "Flushed DNS cache" && return
      fi
      echo "No DNS cache service detected, changes take effect immediately for new lookups"
      ;;
  esac
}

main "$@"
