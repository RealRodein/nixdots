#!/usr/bin/env bash
# Inhibit Niri keyboard shortcuts while Moonlight is focused, so keys such as
# the Super/Mod key reach the remote desktop instead of being eaten by Niri.
#
# Usage:
#   moonlight-inhibit.sh watch   # run as a user service, follows focus changes
#   moonlight-inhibit.sh toggle  # manual escape hatch (bound to Mod+Escape)
#
# Niri ties the inhibitor to the focused surface, so it drops automatically
# when focus moves away. The state file only tracks our own toggles.

set -u

APP_ID="com.moonlight_stream.Moonlight"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-moonlight-inhibit"

state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        printf '0\n'
    fi
}

set_state() {
    printf '%s\n' "$1" > "$STATE_FILE"
}

# Only toggle when needed; niri's action flips the current surface's inhibitor.
toggle_to() {
    desired="$1"
    [ "$(state)" = "$desired" ] && return 0
    niri msg action toggle-keyboard-shortcuts-inhibit >/dev/null 2>&1 || return 1
    set_state "$desired"
}

focused_app_id() {
    niri msg --json windows 2>/dev/null \
        | jq -r '.[] | select(.is_focused == true) | .app_id // empty'
}

case "${1:-}" in
    watch)
        # A fresh watcher owns the state; a stale file could skip enabling.
        rm -f "$STATE_FILE"
        while true; do
            if [ "$(focused_app_id)" = "$APP_ID" ]; then
                toggle_to 1 || true
            else
                # Niri drops the inhibitor when the surface loses focus.
                set_state 0
            fi
            sleep 0.4
        done
        ;;
    toggle)
        app="$(focused_app_id)"
        if [ "$(state)" = "1" ]; then
            if [ "$app" = "$APP_ID" ]; then
                toggle_to 0
            else
                # The inhibitor belonged to the old surface; niri already
                # dropped it, so just forget our toggle.
                set_state 0
            fi
        elif [ "$app" = "$APP_ID" ]; then
            toggle_to 1
        fi
        ;;
    *)
        printf 'usage: %s watch|toggle\n' "$0" >&2
        exit 2
        ;;
esac
