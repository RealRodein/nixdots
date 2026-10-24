#!/usr/bin/env bash

niri msg output eDP-1 mode "1920x1200@60.005" &
sudo auto-cpufreq --force "powersave" --turbo never &
