#!/usr/bin/env bash
set -euo pipefail

URL="https://ingress.inspectr.dev/api/health"
STATE_FILE="$(dirname "$0")/.inspectr_health_state"

status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Accept: application/json" "$URL" || echo "000")
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

notify() {
  local title="$1"
  local message="$2"
  /usr/bin/osascript -e "display notification \"$message\" with title \"$title\""
}

previous_state=""
if [[ -f "$STATE_FILE" ]]; then
  previous_state=$(cat "$STATE_FILE")
fi

if [[ "$status_code" == "200" ]]; then
  if [[ "$previous_state" == "down" ]]; then
    notify "Inspectr Up" "Health check recovered (HTTP 200)."
  fi
  echo "[$timestamp] Inspectr health OK (HTTP 200)"
  echo "up" > "$STATE_FILE"
else
  if [[ "$previous_state" != "down" ]]; then
    notify "Inspectr Down" "Health check failed (HTTP $status_code)."
  fi
  failure_message="[$timestamp] Inspectr health FAIL (HTTP $status_code)"
  echo "$failure_message"
  echo "$failure_message" >&2
  echo "down" > "$STATE_FILE"
  exit 1
fi
