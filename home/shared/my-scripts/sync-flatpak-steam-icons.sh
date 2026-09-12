#!/usr/bin/env bash
set -eu

src_root="$HOME/.var/app/com.valvesoftware.Steam/.local/share/icons/hicolor"
dst_root="$HOME/.local/share/icons/hicolor"
apps_dir="$HOME/.local/share/applications"
cache_root="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/appcache/librarycache"
steam_root="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
icon_size=512
dst_gen_dir="$dst_root/${icon_size}x${icon_size}/apps"
SGDB_TOKEN="${SGDB_TOKEN:-bc5766d607821218e7fdb84ec7eeb1e1}"
SGDB_API_TIMEOUT="${SGDB_API_TIMEOUT:-20}"
SGDB_DOWNLOAD_TIMEOUT="${SGDB_DOWNLOAD_TIMEOUT:-25}"
SGDB_RETRIES="${SGDB_RETRIES:-3}"

mkdir -p "$dst_gen_dir"

download_from_url() {
  url="$1"
  dst="$2"
  attempt=1

  while [ "$attempt" -le "$SGDB_RETRIES" ]; do
    if command -v curl >/dev/null 2>&1; then
      curl -sS -L --max-time "$SGDB_DOWNLOAD_TIMEOUT" -o "$dst" "$url" 2>/dev/null && return 0
    elif command -v wget >/dev/null 2>&1; then
      wget -q -T "$SGDB_DOWNLOAD_TIMEOUT" -O "$dst" "$url" 2>/dev/null && return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  return 1
}

get_steamgriddb_icon_url() {
  app_id="$1"
  [ -n "$SGDB_TOKEN" ] || return 1
  response=""
  attempt=1

  while [ "$attempt" -le "$SGDB_RETRIES" ]; do
    response=$(curl -sS --max-time "$SGDB_API_TIMEOUT" \
      -H "Authorization: Bearer $SGDB_TOKEN" \
      "https://www.steamgriddb.com/api/v2/icons/steam/$app_id?styles=official&types=static&limit=1" \
      2>/dev/null || true)

    if printf '%s' "$response" | rg -q '"success":true' && printf '%s' "$response" | rg -q '"total":[1-9]'; then
      break
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  # If official has no icon, broaden to any icon style (still ICON category endpoint).
  if ! printf '%s' "$response" | rg -q '"success":true' || ! printf '%s' "$response" | rg -q '"total":[1-9]'; then
    response=$(curl -sS --max-time "$SGDB_API_TIMEOUT" \
      -H "Authorization: Bearer $SGDB_TOKEN" \
      "https://www.steamgriddb.com/api/v2/icons/steam/$app_id?types=static&limit=1" \
      2>/dev/null || true)
  fi

  printf '%s' "$response" | rg -q '"success":true' || return 1
  printf '%s' "$response" | rg -q '"total":[1-9]' || return 1

  printf '%s' "$response" \
    | rg -o '"url":"[^"]+"' \
    | head -n 1 \
    | sed 's/^"url":"//; s/"$//' \
    | sed 's#\\/#/#g'
}

convert_to_icon_png() {
  src="$1"
  dst="$2"

  validate_output() {
    out="$1"
    [ -s "$out" ] || return 1

    if command -v magick >/dev/null 2>&1; then
      magick identify "$out" >/dev/null 2>&1 || return 1
      return 0
    fi

    if command -v identify >/dev/null 2>&1; then
      identify "$out" >/dev/null 2>&1 || return 1
      return 0
    fi

    return 0
  }

  if command -v magick >/dev/null 2>&1; then
    scene=$(magick identify -format "%w %s\n" "$src" 2>/dev/null | sort -n | tail -1 | awk '{print $2}')
    [ -n "$scene" ] || scene=0
    magick "${src}[${scene}]" -filter Lanczos -resize "${icon_size}x${icon_size}>" "$dst" >/dev/null 2>&1 && validate_output "$dst" && return 0
    magick "$src" -filter Lanczos -resize "${icon_size}x${icon_size}>" "$dst" >/dev/null 2>&1 && validate_output "$dst" && return 0
  fi

  if command -v convert >/dev/null 2>&1; then
    scene=$(identify -format "%w %s\n" "$src" 2>/dev/null | sort -n | tail -1 | awk '{print $2}')
    [ -n "$scene" ] || scene=0
    convert "${src}[${scene}]" -filter Lanczos -resize "${icon_size}x${icon_size}>" "$dst" >/dev/null 2>&1 && validate_output "$dst" && return 0
    convert "$src" -filter Lanczos -resize "${icon_size}x${icon_size}>" "$dst" >/dev/null 2>&1 && validate_output "$dst" && return 0
  fi

  if command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -y -loglevel error -i "$src" -vf "scale=${icon_size}:${icon_size}:force_original_aspect_ratio=decrease" "$dst" >/dev/null 2>&1 && validate_output "$dst" && return 0
  fi

  return 1
}

choose_steam_small_fallback() {
  app_id="$1"
  cache_dir="$2"

  # Prefer Steam's smallest native icon file.
  if [ -f "$src_root/32x32/apps/steam_icon_${app_id}.png" ]; then
    printf '%s\n' "$src_root/32x32/apps/steam_icon_${app_id}.png"
    return 0
  fi

  # Steam client list icon (typically tiny hashed jpg) as final fallback.
  find "$cache_dir" -maxdepth 1 -type f -name '*.jpg' 2>/dev/null | rg '/[0-9a-f]{40}\.jpg$' | head -n 1 || true
}

collect_steam_app_names() {
  out_file="$1"
  tmp_file=$(mktemp)

  # Common Steam library roots (Flatpak first, then native fallback).
  for root in "$steam_root/steamapps" "$HOME/.local/share/Steam/steamapps"; do
    [ -d "$root" ] || continue

    while IFS= read -r manifest; do
      [ -n "$manifest" ] || continue

      app_id=$(sed -n 's/^[[:space:]]*"appid"[[:space:]]*"\([0-9][0-9]*\)".*/\1/p' "$manifest" | head -n 1)
      app_name=$(sed -n 's/^[[:space:]]*"name"[[:space:]]*"\(.*\)".*/\1/p' "$manifest" | head -n 1)

      [ -n "$app_id" ] || continue
      [ -n "$app_name" ] || continue
      printf '%s\t%s\n' "$app_id" "$app_name" >> "$tmp_file"
    done <<EOF
$(find "$root" -type f -name 'appmanifest_*.acf' 2>/dev/null)
EOF
  done

  # Ensure known app names exist even if manifests are missing.
  printf '312520\tRain World\n' >> "$tmp_file"
  printf '457140\tOxygen Not Included\n' >> "$tmp_file"

  awk -F '\t' '!seen[$1]++ { print $0 }' "$tmp_file" > "$out_file"
  rm -f "$tmp_file"
}

desktop_entry_exists() {
  app_id="$1"
  rg -q "steam://rungameid/${app_id}" "$apps_dir" --glob '*.desktop' 2>/dev/null
}

sanitize_desktop_name() {
  raw_name="$1"
  printf '%s' "$raw_name" \
    | tr '/:' '  ' \
    | tr -cd '[:alnum:][:space:]._()\-'
}

collect_installed_app_ids() {
  out_file="$1"
  tmp_file=$(mktemp)

  collect_from_steamapps_dir() {
    steamapps_dir="$1"
    [ -d "$steamapps_dir" ] || return 0

    find "$steamapps_dir" -maxdepth 1 -type f -name 'appmanifest_*.acf' 2>/dev/null \
      | sed -n 's#.*/appmanifest_\([0-9][0-9]*\)\.acf$#\1#p' \
      >> "$tmp_file"

    library_vdf="$steamapps_dir/libraryfolders.vdf"
    if [ -f "$library_vdf" ]; then
      while IFS= read -r library_path; do
        [ -n "$library_path" ] || continue
        lib_steamapps="$library_path/steamapps"
        [ -d "$lib_steamapps" ] || continue
        find "$lib_steamapps" -maxdepth 1 -type f -name 'appmanifest_*.acf' 2>/dev/null \
          | sed -n 's#.*/appmanifest_\([0-9][0-9]*\)\.acf$#\1#p' \
          >> "$tmp_file"
      done <<EOF
$(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)".*/\1/p' "$library_vdf")
EOF
    fi
  }

  collect_from_steamapps_dir "$steam_root/steamapps"
  collect_from_steamapps_dir "$HOME/.local/share/Steam/steamapps"

  sort -u "$tmp_file" | rg '^[0-9]+$' > "$out_file" || true
  rm -f "$tmp_file"
}

remove_stale_desktop_entries() {
  installed_ids_file="$1"
  removed_file="$2"

  : > "$removed_file"

  find "$apps_dir" -maxdepth 1 -type f -name '*.desktop' 2>/dev/null | while IFS= read -r desktop_file; do
    app_id=$(sed -n 's#^Exec=.*steam://rungameid/\([0-9][0-9]*\).*$#\1#p' "$desktop_file" | head -n 1)
    app_name=$(sed -n 's#^Name=\(.*\)$#\1#p' "$desktop_file" | head -n 1)
    [ -n "$app_id" ] || continue

    # Always remove placeholder launcher entries such as "Steam App 123456".
    if printf '%s' "$app_name" | rg -q '^Steam App [0-9]+$'; then
      rm -f "$desktop_file"
      printf '%s\n' "$desktop_file" >> "$removed_file"
      continue
    fi

    if ! rg -qx "$app_id" "$installed_ids_file" 2>/dev/null; then
      rm -f "$desktop_file"
      printf '%s\n' "$desktop_file" >> "$removed_file"
    fi
  done
}

create_missing_desktop_entry() {
  app_id="$1"
  app_name="$2"

  base_name=$(sanitize_desktop_name "$app_name" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')
  [ -n "$base_name" ] || base_name="Steam App ${app_id}"

  dst_desktop="$apps_dir/${base_name}.desktop"
  if [ -e "$dst_desktop" ]; then
    dst_desktop="$apps_dir/${base_name} (${app_id}).desktop"
  fi

  cat > "$dst_desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=${app_name}
Exec=flatpak run com.valvesoftware.Steam steam steam://rungameid/${app_id}
Icon=steam_icon_${app_id}
Terminal=false
Categories=Game;
StartupWMClass=steam_app_${app_id}
EOF

  chmod 644 "$dst_desktop"
}

generated=0
sgdb_used=0
fallback_used=0
skipped=0
desktop_created=0
desktop_skipped=0
desktop_removed=0
desktop_name_unknown_skipped=0

needed_file=$(mktemp)
app_names_file=$(mktemp)
needed_ids_file=$(mktemp)
installed_ids_file=$(mktemp)
removed_desktops_file=$(mktemp)

# Always include explicitly requested app IDs, even if no desktop Icon= entry exists yet.
manual_app_ids='312520 457140'

collect_installed_app_ids "$installed_ids_file"
remove_stale_desktop_entries "$installed_ids_file" "$removed_desktops_file"
desktop_removed=$(wc -l < "$removed_desktops_file" | tr -d ' ')

{
  # Existing icon references from desktop entries.
  rg --no-filename -o 'steam_icon_[0-9]+' "$apps_dir"/*.desktop 2>/dev/null || true

  # Steam launch URLs in Exec lines (steam://rungameid/APPID) converted to icon names.
  rg --no-filename -o 'steam://rungameid/[0-9]+' "$apps_dir"/*.desktop 2>/dev/null \
    | sed 's#steam://rungameid/#steam_icon_#' || true

  # User-forced IDs for newly added games.
  for app_id in $manual_app_ids; do
    printf 'steam_icon_%s\n' "$app_id"
  done

  # Installed app IDs should also be eligible for icon generation.
  while IFS= read -r app_id; do
    [ -n "$app_id" ] || continue
    printf 'steam_icon_%s\n' "$app_id"
  done < "$installed_ids_file"
} | sort -u > "$needed_file"

sed 's/^steam_icon_//' "$needed_file" | rg '^[0-9]+$' | sort -u > "$needed_ids_file"
collect_steam_app_names "$app_names_file"

while IFS= read -r app_id; do
  [ -n "$app_id" ] || continue

  # Only keep/create launchers for currently installed games.
  if ! rg -qx "$app_id" "$installed_ids_file" 2>/dev/null; then
    continue
  fi

  if desktop_entry_exists "$app_id"; then
    desktop_skipped=$((desktop_skipped + 1))
    continue
  fi

  app_name=$(awk -F '\t' -v id="$app_id" '$1 == id { print $2; exit }' "$app_names_file")
  if [ -z "$app_name" ]; then
    desktop_name_unknown_skipped=$((desktop_name_unknown_skipped + 1))
    continue
  fi

  create_missing_desktop_entry "$app_id" "$app_name"
  desktop_created=$((desktop_created + 1))
done < "$needed_ids_file"

while IFS= read -r icon_name; do
  [ -n "$icon_name" ] || continue

  app_id="${icon_name#steam_icon_}"
  dst_img="$dst_gen_dir/$icon_name.png"

  # Skip if the icon already exists
  if [ -f "$dst_img" ] && [ -s "$dst_img" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  cache_dir="$cache_root/$app_id"

  tmp_img=$(mktemp --suffix=.png)
  created=0

  # Primary: SteamGridDB ICON endpoint (official first, then any style).
  sgdb_url=$(get_steamgriddb_icon_url "$app_id" || true)
  if [ -n "$sgdb_url" ]; then
    case "$sgdb_url" in
      *.ico*) tmp_dl=$(mktemp --suffix=.ico) ;;
      *.png*) tmp_dl=$(mktemp --suffix=.png) ;;
      *.webp*) tmp_dl=$(mktemp --suffix=.webp) ;;
      *.jpg*|*.jpeg*) tmp_dl=$(mktemp --suffix=.jpg) ;;
      *) tmp_dl=$(mktemp --suffix=.img) ;;
    esac
    if download_from_url "$sgdb_url" "$tmp_dl" && [ -s "$tmp_dl" ] && convert_to_icon_png "$tmp_dl" "$tmp_img"; then
      mv "$tmp_img" "$dst_img"
      chmod 644 "$dst_img"
      created=1
      sgdb_used=$((sgdb_used + 1))
    fi
    rm -f "$tmp_dl"
  fi

  # Fallback: tiny native Steam icon.
  if [ "$created" -eq 0 ] && [ -d "$cache_dir" ]; then
    src_img=$(choose_steam_small_fallback "$app_id" "$cache_dir")
    if [ -n "$src_img" ] && convert_to_icon_png "$src_img" "$tmp_img"; then
      mv "$tmp_img" "$dst_img"
      chmod 644 "$dst_img"
      created=1
      fallback_used=$((fallback_used + 1))
    fi
  fi

  if [ "$created" -eq 1 ]; then
    generated=$((generated + 1))
  else
    rm -f "$tmp_img"
  fi
done < "$needed_file"

rm -f "$needed_file"
rm -f "$needed_ids_file"
rm -f "$app_names_file"
rm -f "$installed_ids_file"
rm -f "$removed_desktops_file"

gtk-update-icon-cache -f "$dst_root" >/dev/null 2>&1 || true
update-desktop-database "$apps_dir" >/dev/null 2>&1 || true

printf '✓ Icons generated: %s (steamgriddb: %s, fallback: %s) | Skipped existing: %s\n' "$generated" "$sgdb_used" "$fallback_used" "$skipped"
printf '✓ Desktop entries created: %s | Skipped existing: %s\n' "$desktop_created" "$desktop_skipped"
printf '✓ Desktop entries removed (not installed): %s\n' "$desktop_removed"
printf '✓ Desktop entries skipped (unknown app name): %s\n' "$desktop_name_unknown_skipped"
