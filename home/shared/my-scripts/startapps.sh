#!/usr/bin/env bash

if command -v taskset >/dev/null 2>&1 && [ "$(nproc)" -ge 12 ]; then
  taskset -c 0-11 steam &
else
  steam &
fi

vesktop &
rog-control-center &

if [ -x "$HOME/Applications/miner/run.sh" ]; then
  "$HOME/Applications/miner/run.sh" & disown
fi
