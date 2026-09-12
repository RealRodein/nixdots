#!/usr/bin/env sh
set -eu

pdf_file=${1:-}
if [ -z "$pdf_file" ]; then
  printf '%s\n' "No PDF file was provided." >&2
  exit 1
fi

if ! command -v pdftotext >/dev/null 2>&1; then
  printf '%s\n' "pdftotext is required for terminal PDF view." >&2
  printf '%s\n' "Install it and retry:" >&2
  printf '%s\n' "  Debian/Ubuntu: sudo apt install poppler-utils" >&2
  printf '%s\n' "  Arch: sudo pacman -S poppler" >&2
  printf '%s\n' "  Fedora: sudo dnf install poppler-utils" >&2
  printf '\n%s' "Press Enter to return to Yazi..." >&2
  read -r _
  exit 1
fi

tmp_file=$(mktemp)
cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT INT TERM

pdftotext -layout "$pdf_file" "$tmp_file"
"${PAGER:-less}" "$tmp_file"
