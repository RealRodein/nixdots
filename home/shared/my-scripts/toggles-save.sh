#!/bin/bash
# Niri needs to know which session to talk to
export WAYLAND_DISPLAY=wayland-0 &

niri msg output eDP-1 mode "1920x1200@60.005" &
sudo auto-cpufreq --force "powersave" --turbo never &
