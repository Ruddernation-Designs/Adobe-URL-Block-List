#!/usr/bin/env bash
# Reverts the Adobe blocklist from the system hosts file on macOS and Linux.
#
# Removes the block between the marker comments that apply.sh added,
# leaving the rest of the hosts file untouched.
#
# Usage: sudo ./revert.sh
set -euo pipefail

START_MARKER="## ADOBE_BLOCKLIST_START ##"
END_MARKER="## ADOBE_BLOCKLIST_END ##"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_HOSTS_FILE="$SCRIPT_DIR/hosts.bak"
# Overridable so the scripts can be tested without touching the real hosts file
SYS_HOSTS_FILE="${ADOBE_BLOCKLIST_HOSTS_FILE:-/etc/hosts}"

main() {
  check_preconditions
  remove_block
  flush_dns_cache
  echo "Reverted $SYS_HOSTS_FILE"
}

check_preconditions() {
  if ! grep -qF "$START_MARKER" "$SYS_HOSTS_FILE"; then
    echo "No blocklist markers found in $SYS_HOSTS_FILE, nothing to revert." >&2
    if [[ -f "$BACKUP_HOSTS_FILE" ]]; then
      echo "If you applied the records manually, you can restore the backup with:" >&2
      echo "  sudo cp '$BACKUP_HOSTS_FILE' '$SYS_HOSTS_FILE'" >&2
    fi
    exit 1
  fi

  if [[ ! -w "$SYS_HOSTS_FILE" ]]; then
    echo "Cannot write to $SYS_HOSTS_FILE. Please re-run with sudo: sudo $0" >&2
    exit 1
  fi
}

remove_block() {
  local temp_file
  temp_file="$(mktemp)"
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
  ' "$SYS_HOSTS_FILE" > "$temp_file"
  cat "$temp_file" > "$SYS_HOSTS_FILE"
  rm -f "$temp_file"
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
