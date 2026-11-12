#!/usr/bin/env bash
set -euo pipefail

# Wrapper to handle rog-control-center single-instance/tray issue.
# If already running, try to show its window; otherwise kill and relaunch.

PID=$(pgrep -x rog-control-center || true)

if [ -n "$PID" ]; then
  # Already running – try to bring it to the foreground / show window
  # Many tray apps accept --activate or we can try to send a normal signal
  if rog-control-center --show-window 2>/dev/null; then
    : # success
  elif pgrep -x "rog-control-center" >/dev/null 2>&1; then
    # If --show-window not supported, just restart cleanly
    pkill -f rog-control-center || true
    sleep 0.3
    rog-control-center &
  fi
else
  rog-control-center &
fi