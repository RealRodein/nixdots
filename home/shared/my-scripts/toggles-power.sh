#!/usr/bin/env bash

niri msg output eDP-1 mode "1920x1200@165.015" &
sudo auto-cpufreq --force "performance" --turbo never &
