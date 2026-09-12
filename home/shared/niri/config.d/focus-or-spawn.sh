#!/usr/bin/env bash
# focus-or-spawn.sh: scratchpad/overlay toggle for niri
# Usage: focus-or-spawn.sh <match_token> <spawn_command...> [--on-focused <focus_command...>]
#
# Matching order:
# 1) exact app_id match
# 2) case-insensitive contains() on app_id
# 3) case-insensitive contains() on title
#
# Press once -> app not running: spawn it
# Press again -> app running, not focused: save current window, focus app
# Press again -> app already focused: run <focus_command> (if --on-focused),
#   otherwise restore previously focused window

MATCH="${1:-}"
if [ -z "$MATCH" ]; then
    exit 2
fi
shift

ON_FOCUSED=()
SPAWN_CMD=()
while [ $# -gt 0 ]; do
    if [ "$1" = "--on-focused" ]; then
        shift
        ON_FOCUSED=("$@")
        break
    fi
    SPAWN_CMD+=("$1")
    shift
done

STATE_FILE="/tmp/niri-overlay-prev-$(printf '%s' "$MATCH" | tr '[:upper:] /' '[:lower:]-')"

# If niri/jq are missing or niri isn't available yet, fall back to spawn.
if ! command -v niri >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exec "${SPAWN_CMD[@]}"
fi

WINDOWS=$(niri msg --json windows 2>/dev/null)

if [ -z "$WINDOWS" ]; then
    exec "${SPAWN_CMD[@]}"
fi

MATCH_LOWER=$(printf '%s' "$MATCH" | tr '[:upper:]' '[:lower:]')

APP_WIN_ID=$(printf '%s' "$WINDOWS" | jq -r --arg m "$MATCH" --arg ml "$MATCH_LOWER" '
    [ .[]
      | select(
            (.app_id // "") == $m
            or ((.app_id // "") | ascii_downcase | contains($ml))
            or ((.title // "") | ascii_downcase | contains($ml))
        )
    ]
    | sort_by((.focus_timestamp.secs // 0), (.focus_timestamp.nanos // 0))
    | last
    | .id // empty
')

FOCUSED_ID=$(printf '%s' "$WINDOWS" | jq -r '.[] | select(.is_focused == true) | .id // empty')

if [ -z "$APP_WIN_ID" ]; then
    exec "${SPAWN_CMD[@]}"
elif [ "$FOCUSED_ID" = "$APP_WIN_ID" ]; then
    if [ ${#ON_FOCUSED[@]} -gt 0 ]; then
        exec "${ON_FOCUSED[@]}"
    elif [ -f "$STATE_FILE" ]; then
        PREV_ID=$(cat "$STATE_FILE")
        niri msg action focus-window --id "$PREV_ID" 2>/dev/null || true
    fi
else
    [ -n "$FOCUSED_ID" ] && printf '%s' "$FOCUSED_ID" > "$STATE_FILE"
    niri msg action focus-window --id "$APP_WIN_ID"
fi
