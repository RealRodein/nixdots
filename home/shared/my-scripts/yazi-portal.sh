#!/bin/bash
set -e

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

kitty_args=(--class yazi -o confirm_os_window_close=0 -e yazi)

if [ "$save" = "1" ]; then
	kitty_args+=(--chooser-file="$out" "$path")
elif [ "$directory" = "1" ]; then
	kitty_args+=(--chooser-file="$out" --cwd-file="$out.1" "$path")
elif [ "$multiple" = "1" ]; then
	kitty_args+=(--chooser-file="$out" "$path")
else
	kitty_args+=(--chooser-file="$out" "$path")
fi

kitty "${kitty_args[@]}"

