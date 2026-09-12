#!/usr/bin/env bash
set -euo pipefail

THEME="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes/noctalia"

[ -f "$THEME" ] || exit 0

bg=$(grep '^background' "$THEME" | head -1 | cut -d= -f2 | tr -d ' ')
fg=$(grep '^foreground' "$THEME" | head -1 | cut -d= -f2 | tr -d ' ')

[ -z "$bg" ] || [ -z "$fg" ] && exit 0

grep -q '^window-titlebar-background' "$THEME" || {
    printf '\nwindow-titlebar-background = %s\nwindow-titlebar-foreground = %s\n' "$bg" "$fg" >> "$THEME"
}

pgrep -f ghostty >/dev/null && pkill -SIGUSR2 ghostty || true
