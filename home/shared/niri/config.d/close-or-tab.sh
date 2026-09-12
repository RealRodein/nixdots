#!/usr/bin/env bash
# close-or-tab.sh: close window normally, or close tab if ghostty focused

if niri msg focused-window 2>/dev/null | grep -qi 'com.mitchellh.ghostty'; then
    exec wtype -M ctrl -M shift -k w
else
    exec niri msg action close-window
fi
