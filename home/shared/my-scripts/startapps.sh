#!/usr/bin/env bash
taskset -c 0-11 steam &
vesktop &
rog-control-center &

~/Applications/miner/run.sh & disown
