#!/usr/bin/env bash
# sandbox.sh - run an untrusted program in a hardened bubblewrap box
#
# usage: sandbox.sh                        interactive picker over the library
#        sandbox.sh soulslike/             picker over LIB/soulslike
#        sandbox.sh /any/other/dir         picker over that dir directly
#        sandbox.sh /path/to/program.exe   launch that file directly (wine)
#        sandbox.sh /path/to/native-bin    launch that file directly (native)
#        sandbox.sh --attach <pid|name>    attach shell to running sandbox
#
# Flags (can appear before or after the path, in any order):
#   --write-dir / --read-only-dir      program's own folder rw / ro (default: ro)
#   --persist / --ephemeral            keep wine prefix / wipe on exit (default: persist)
#   --x11 / --wayland                  allow X11 socket / Wayland only (default: wayland)
#   --input / --no-input               pass /dev/input through (default: no)
#   --seccomp / --no-seccomp           enable/disable the syscall deny-list (default: on)
#   --nwjs-native / --nwjs-wine        run NW.js bundles with native NW.js (default: wine)
#   --no-job-tuning                    don't pass -job-worker-count to Unity-style builds
#   --root-persist / --no-root-persist persist root-level saves (/savedata etc.)
#   --diag / --no-diag                 one-shot startup graphics diagnostic (default: on)
#   --debug / --no-debug               verbose Mesa/EGL/Vulkan runtime logging (default: off)
#   -h / --help                        print this usage and exit

# --- Packages that could be removed/disabled from nix config ---
# The following nix packages are referenced in the config because of this
# script's capabilities, but could potentially be removed/disabled:
#   - bubblewrap (bwrap): Core sandbox mechanism used by this script.
#     (found in: modules/nixos/packages/cli.nix) - script requires this
#   - nwjs, electron, seccomp: Runtime support built into script flags.
#     Does not require specific nix package enablement.
#   - winetricks: Included in gaming config; may not be needed if not using
#     proton-ge or Windows executables via this script.
#   - WARNING: Do NOT remove 'steam' or steam-related packages from gaming.nix
#     as they are implicitly used/required by Steam/Proton pipeline.
#     (found in: modules/nixos/features/gaming.nix)
#   - Gaming packages (gamescope, mangohud, heroic, prismlauncher) from
#     gaming.nix are NOT directly required by this script and could be
#     removed/disabled if desired.
# --- END package removal notes ---

set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
TEMPLATE="$CACHE/sandbox/wine-template"
LIB="/mnt/origin/games/SailingSeas"      # hardcoded default library root
ENV_ROOT="/mnt/origin/games/SailingSeas/ENV"
LOG_FILE="${SANDBOX_LOG:-}"              # empty = stderr only

print_usage() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Logging infrastructure
# ---------------------------------------------------------------------------
sandbox_log() {
  local level="$1"; shift
  local ts; ts="$(date +%T)"
  local line="sandbox [$ts] [$level] $*"
  echo -e "$line" >&2
  if [[ -n "$LOG_FILE" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    echo -e "$line" >> "$LOG_FILE"
  fi
}

# ---------------------------------------------------------------------------
# Attach handler (--attach)
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--attach" ]]; then
  shift
  target="${1:-}"
  if [[ -z "$target" ]]; then
    sandbox_log ERROR "Usage: sandbox.sh --attach <pid|name>"
    exit 1
  fi
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    bwrap_pid="$target"
  else
    bwrap_pid=$(pgrep -f "bwrap.*$target" | head -n1 || true)
  fi
  if [[ -z "$bwrap_pid" || ! -d "/proc/$bwrap_pid" ]]; then
    sandbox_log ERROR "No running sandbox found matching: $target"
    exit 1
  fi
  sandbox_log INFO "Attaching interactive shell to sandbox (PID $bwrap_pid)..."
  exec nsenter -t "$bwrap_pid" --mount --pid --net --uts --ipc -- /bin/sh
fi

# ---------------------------------------------------------------------------
# Defaults & Option setup
# ---------------------------------------------------------------------------
OPT_WRITE_DIR="${SANDBOX_WRITE_DIR:-${SANDBOX_WRITE_GAMEDIR:-0}}"
OPT_PERSIST="${SANDBOX_PERSIST:-1}"
OPT_X11="${SANDBOX_X11:-0}"
OPT_INPUT="${SANDBOX_INPUT:-0}"
OPT_UNITY_JOBS="${SANDBOX_UNITY_JOBS:-1}"
OPT_ROOTPERSIST="${SANDBOX_ROOTPERSIST:-1}"
OPT_DIAG="${SANDBOX_DIAG:-1}"
OPT_DEBUG="${SANDBOX_DEBUG:-0}"
OPT_SECCOMP=1
[[ "${SANDBOX_NO_SECCOMP:-0}" == "1" ]] && OPT_SECCOMP=0
OPT_NWJS_NATIVE="${SANDBOX_NWJS_NATIVE:-0}"

# Track explicit CLI flag overrides: CLI > .sandbox-config > Env/Defaults
declare -A CLI_EXPLICIT=()

parse_flags() {
  local args=("$@")
  POSITIONAL=()
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    local arg="${args[$i]}"
    case "$arg" in
      --write-dir)       OPT_WRITE_DIR=1; CLI_EXPLICIT[WRITE_DIR]=1 ;;
      --read-only-dir)   OPT_WRITE_DIR=0; CLI_EXPLICIT[WRITE_DIR]=1 ;;
      --persist)         OPT_PERSIST=1;   CLI_EXPLICIT[PERSIST]=1 ;;
      --ephemeral)       OPT_PERSIST=0;   CLI_EXPLICIT[PERSIST]=1 ;;
      --x11)             OPT_X11=1;       CLI_EXPLICIT[X11]=1 ;;
      --wayland)         OPT_X11=0;       CLI_EXPLICIT[X11]=1 ;;
      --input)           OPT_INPUT=1;     CLI_EXPLICIT[INPUT]=1 ;;
      --no-input)        OPT_INPUT=0;     CLI_EXPLICIT[INPUT]=1 ;;
      --seccomp)         OPT_SECCOMP=1;   CLI_EXPLICIT[SECCOMP]=1 ;;
      --no-seccomp)      OPT_SECCOMP=0;   CLI_EXPLICIT[SECCOMP]=1 ;;
      --no-job-tuning)   OPT_UNITY_JOBS=0; CLI_EXPLICIT[UNITY_JOBS]=1 ;;
      --root-persist)    OPT_ROOTPERSIST=1; CLI_EXPLICIT[ROOTPERSIST]=1 ;;
      --no-root-persist) OPT_ROOTPERSIST=0; CLI_EXPLICIT[ROOTPERSIST]=1 ;;
      --diag)            OPT_DIAG=1;      CLI_EXPLICIT[DIAG]=1 ;;
      --no-diag)         OPT_DIAG=0;      CLI_EXPLICIT[DIAG]=1 ;;
      --debug)           OPT_DEBUG=1;     CLI_EXPLICIT[DEBUG]=1 ;;
      --no-debug)        OPT_DEBUG=0;     CLI_EXPLICIT[DEBUG]=1 ;;
      --nwjs-native)     OPT_NWJS_NATIVE=1; CLI_EXPLICIT[NWJS_NATIVE]=1 ;;
      --nwjs-wine)       OPT_NWJS_NATIVE=0; CLI_EXPLICIT[NWJS_NATIVE]=1 ;;
      -h|--help)         print_usage; exit 0 ;;
      --)
        i=$((i+1))
        while [[ $i -lt ${#args[@]} ]]; do POSITIONAL+=("${args[$i]}"); i=$((i+1)); done
        break
        ;;
      -*)
        sandbox_log ERROR "unknown flag: $arg"
        sandbox_log ERROR "run with --help to see available flags."
        exit 1
        ;;
      *) POSITIONAL+=("$arg") ;;
    esac
    i=$((i+1))
  done
}

parse_flags "$@"
set -- "${POSITIONAL[@]}"

# ---------------------------------------------------------------------------
# ENV Runner Utilities (/mnt/origin/games/SailingSeas/ENV/)
# ---------------------------------------------------------------------------
ensure_env_dir() {
  mkdir -p "$ENV_ROOT"/{wine,nwjs,electron}
}

extract_if_archive() {
  local src="$1" dst_dir="$2"
  local base="${src##*/}"
  [[ -e "$src" && ! -e "$dst_dir" ]] || return 0
  mkdir -p "$dst_dir"
  case "$base" in
    *.tar.xz)
      sandbox_log INFO "extracting $base -> ${dst_dir%/}"
      tar -xJf "$src" -C "$(dirname "$dst_dir")" 2>/dev/null || tar -xJf "$src" -C "$dst_dir" 2>/dev/null || true
      ;;
    *.tar.gz|*.tgz)
      sandbox_log INFO "extracting $base -> ${dst_dir%/}"
      tar -xzf "$src" -C "$(dirname "$dst_dir")" 2>/dev/null || tar -xzf "$src" -C "$dst_dir" 2>/dev/null || true
      ;;
    *.zip)
      sandbox_log INFO "extracting $base -> ${dst_dir%/}"
      if command -v unzip >/dev/null 2>&1; then
        unzip -q "$src" -d "$(dirname "$dst_dir")" 2>/dev/null || unzip -q "$src" -d "$dst_dir" 2>/dev/null || true
      else
        python3 -c "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); z.extractall(sys.argv[2])" "$src" "$(dirname "$dst_dir")" 2>/dev/null || true
      fi
      ;;
  esac
}

resolve_env_runner() {
  local runner_spec="$1" # e.g. nwjs/nwjs-v0.45.3-linux-x64 or wine/wine-ge-8-26-x86_64
  [[ -z "$runner_spec" ]] && return 1
  ensure_env_dir
  local rel="$runner_spec"
  rel="${rel#/}"
  local basepath="$ENV_ROOT/$rel"
  if [[ -d "$basepath" ]]; then
    echo "$basepath"
    return 0
  fi
  local kind="${rel%%/*}"
  local name="${rel#*/}"
  local cand
  for cand in "$ENV_ROOT/$kind/$name".{tar.xz,tar.gz,tgz,zip}; do
    if [[ -f "$cand" ]]; then
      extract_if_archive "$cand" "$basepath"
      if [[ -d "$basepath" ]]; then
        echo "$basepath"
        return 0
      fi
    fi
  done
  if [[ -d "$ENV_ROOT/$kind" ]]; then
    local d
    for d in "$ENV_ROOT/$kind"/*; do
      [[ -d "$d" ]] || continue
      if [[ "${d##*/}" == *"$name"* ]]; then
        echo "$d"
        return 0
      fi
    done
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Executable scanner & picker
# ---------------------------------------------------------------------------
JUNK_EXE_PATTERNS=(
  '*crashhandler*' '*crash-handler*' '*crash_reporter*' '*crashpad*'
  '*ue4prereqsetup*' '*ueprereqsetup*' '*vc_redist*' '*vcredist*'
  '*dxsetup*' '*directx*' '*dotnet*' '*unins*' '*setup*' '*installer*'
  '*battleye*' '*easyanticheat*' '*eac_launcher*'
)

is_plausible_executable() {
  local f="$1" size magic
  size="$(stat -c %s -- "$f" 2>/dev/null || echo 0)"
  [[ "$size" -gt 0 ]] || return 1
  magic="$(head -c 4 -- "$f" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
  case "${f,,}" in
    *.exe|*.msi)
      [[ "$magic" == 4d5a* || "$magic" == d0cf11e0* ]]
      ;;
    *.bat|*.cmd)
      return 0
      ;;
    *)
      [[ "$magic" == 7f454c46 || "$magic" == 2321* ]]
      ;;
  esac
}

find_candidate_exe() {
  local args=(find "$1" -maxdepth "$2" -type f \( -iname '*.exe' -o -iname '*.x86_64' -o -iname '*.x86' -o -iname '*.linux' -o -iname '*.elf' -o -iname '*.run' -o -iname '*.appimage' -o -perm -u+x \))
  for pat in "${JUNK_EXE_PATTERNS[@]}"; do
    args+=(-not -iname "$pat")
  done
  args+=(-not -iname '*.so')
  local best="" sz p
  while IFS=$'\t' read -r sz p; do
    [[ -n "$best" ]] || best="$p"
    if is_plausible_executable "$p"; then
      printf '%s\n' "$p"
      return 0
    fi
  done < <("${args[@]}" -printf '%s\t%p\n' 2>/dev/null | sort -rn)
  
  if [[ -n "$best" ]]; then
    printf '%s\n' "$best"
  fi
  return 0
}

scan_programs() {
  [[ -d "$1" ]] || return 0
  local root_dir="$1" base exe dirs d

  exe="$(find_candidate_exe "$root_dir" 1)"
  [[ -n "$exe" ]] && printf '%s\t%s\n' "${root_dir##*/}" "$exe"

  mapfile -d '' dirs < <(find "$root_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
  for d in "${dirs[@]}"; do
    base="${d##*/}"
    [[ "$base" == .* || "$base" == *.part ]] && continue
    exe="$(find_candidate_exe "$d" 1)"
    [[ -n "$exe" ]] && printf '%s\t%s\n' "$base" "$exe"
  done
}

onoff() { [[ "$1" == "1" ]] && echo "on" || echo "off"; }

read_key() {
  if [[ -t 0 ]]; then
    IFS= read -r "$@" || return 1
  else
    if IFS= read -r "$@" </dev/tty 2>/dev/null; then
      return 0
    else
      IFS= read -r "$@" || return 1
    fi
  fi
}

toggles_menu() {
  local key
  while true; do
    echo
    echo "toggles for this launch (press number to flip):"
    printf ' [1] write dir           : %s\n' "$(onoff "$OPT_WRITE_DIR")"
    printf ' [2] persist prefix      : %s\n' "$(onoff "$OPT_PERSIST")"
    printf ' [3] x11 (off = wayland) : %s\n' "$(onoff "$OPT_X11")"
    printf ' [4] input passthrough   : %s\n' "$(onoff "$OPT_INPUT")"
    printf ' [5] seccomp filter      : %s\n' "$(onoff "$OPT_SECCOMP")"
    printf ' [6] unity job tuning    : %s\n' "$(onoff "$OPT_UNITY_JOBS")"
    printf ' [7] persist /-root saves: %s\n' "$(onoff "$OPT_ROOTPERSIST")"
    printf ' [8] startup gfx diag    : %s\n' "$(onoff "$OPT_DIAG")"
    printf ' [9] verbose gfx logging : %s\n' "$(onoff "$OPT_DEBUG")"
    printf ' [0] native nwjs (NW.js)  : %s\n' "$(onoff "$OPT_NWJS_NATIVE")"
    echo " [b] back"
    printf '> '
    read_key -n1 key || return 0
    echo
    case "$key" in
      1) OPT_WRITE_DIR=$(( 1 - OPT_WRITE_DIR )); CLI_EXPLICIT[WRITE_DIR]=1 ;;
      2) OPT_PERSIST=$(( 1 - OPT_PERSIST ));     CLI_EXPLICIT[PERSIST]=1 ;;
      3) OPT_X11=$(( 1 - OPT_X11 ));             CLI_EXPLICIT[X11]=1 ;;
      4) OPT_INPUT=$(( 1 - OPT_INPUT ));         CLI_EXPLICIT[INPUT]=1 ;;
      5) OPT_SECCOMP=$(( 1 - OPT_SECCOMP ));     CLI_EXPLICIT[SECCOMP]=1 ;;
      6) OPT_UNITY_JOBS=$(( 1 - OPT_UNITY_JOBS )); CLI_EXPLICIT[UNITY_JOBS]=1 ;;
      7) OPT_ROOTPERSIST=$(( 1 - OPT_ROOTPERSIST )); CLI_EXPLICIT[ROOTPERSIST]=1 ;;
      8) OPT_DIAG=$(( 1 - OPT_DIAG ));           CLI_EXPLICIT[DIAG]=1 ;;
      9) OPT_DEBUG=$(( 1 - OPT_DEBUG ));         CLI_EXPLICIT[DEBUG]=1 ;;
      0) OPT_NWJS_NATIVE=$(( 1 - OPT_NWJS_NATIVE )); CLI_EXPLICIT[NWJS_NATIVE]=1 ;;
      b|B) return 0 ;;
    esac
  done
}

menu() {
  local search_root="$1"
  local -a names=() exes=()
  local name exe key i rel_exe

  while true; do
    names=(); exes=()
    while IFS=$'\t' read -r name exe; do
      names+=("$name"); exes+=("$exe")
    done < <(scan_programs "$search_root")

    echo
    if [[ ${#names[@]} -eq 0 ]]; then
      sandbox_log WARN "no launchable targets found in: $search_root"
      return 1
    fi

    for ((i=0; i<${#names[@]}; i++)); do
      rel_exe="${exes[i]#"$search_root"/}"
      printf '[%2d] - %-35s \e[2m(%s)\e[0m\n' "$((i + 1))" "${names[i]}" "$rel_exe"
    done

    echo " [t] - toggles"
    echo " [r] - refresh"
    echo " [q] - quit"
    printf 'entry number> '

    read_key key || exit 0
    case "$key" in
      "") continue ;;
      q|Q) exit 0 ;;
      r|R) continue ;;
      t|T) toggles_menu; continue ;;
      *)
        if [[ "$key" =~ ^[0-9]+$ ]]; then
          if [[ "$key" -ge 1 && "$key" -le "${#exes[@]}" ]]; then
            LAUNCH_TARGET="${exes[$((key - 1))]}"; return 0
          else
            sandbox_log ERROR "out of range (1–${#exes[@]}): $key"
          fi
        else
          sandbox_log ERROR "invalid input: $key"
        fi
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Target Resolution & Per-Game Config Merge
# ---------------------------------------------------------------------------
LAUNCH_TARGET=""
if [[ $# -eq 0 ]]; then
  menu "$LIB" || exit 1
elif [[ -d "$1" ]]; then
  menu "$(readlink -f "$1")" || exit 1
  shift
elif [[ -d "$LIB/${1%/}" ]]; then
  menu "$(readlink -f "$LIB/${1%/}")" || exit 1
  shift
else
  LAUNCH_TARGET="$1"
  shift
fi

[[ -n "$LAUNCH_TARGET" ]] || { sandbox_log ERROR "no target selected."; exit 1; }
TARGET="$(readlink -f "$LAUNCH_TARGET")"
[[ -f "$TARGET" ]] || { sandbox_log ERROR "no such file: $TARGET"; exit 1; }

PROG_DIR="$(dirname "$TARGET")"
NAME="${TARGET##*/}"

# Load per-game config file if present ($PROG_DIR/.sandbox-config)
GAME_CFG="$PROG_DIR/.sandbox-config"
GAME_SANDBOX_RUNNER=""
if [[ -f "$GAME_CFG" ]]; then
  sandbox_log INFO "loaded per-game config: $GAME_CFG"
  set +e
  source "$GAME_CFG" 2>/dev/null
  set -e
  [[ -z "${CLI_EXPLICIT[WRITE_DIR]:-}" && -n "${SANDBOX_WRITE_DIR:-}" ]] && OPT_WRITE_DIR="$SANDBOX_WRITE_DIR"
  [[ -z "${CLI_EXPLICIT[PERSIST]:-}" && -n "${SANDBOX_PERSIST:-}" ]] && OPT_PERSIST="$SANDBOX_PERSIST"
  [[ -z "${CLI_EXPLICIT[X11]:-}" && -n "${SANDBOX_X11:-}" ]] && OPT_X11="$SANDBOX_X11"
  [[ -z "${CLI_EXPLICIT[INPUT]:-}" && -n "${SANDBOX_INPUT:-}" ]] && OPT_INPUT="$SANDBOX_INPUT"
  [[ -z "${CLI_EXPLICIT[SECCOMP]:-}" && -n "${SANDBOX_NO_SECCOMP:-}" ]] && {
    [[ "$SANDBOX_NO_SECCOMP" == "1" ]] && OPT_SECCOMP=0 || OPT_SECCOMP=1
  }
  [[ -z "${CLI_EXPLICIT[SECCOMP]:-}" && -n "${SANDBOX_SECCOMP:-}" ]] && OPT_SECCOMP="$SANDBOX_SECCOMP"
  [[ -z "${CLI_EXPLICIT[UNITY_JOBS]:-}" && -n "${SANDBOX_UNITY_JOBS:-}" ]] && OPT_UNITY_JOBS="$SANDBOX_UNITY_JOBS"
  [[ -z "${CLI_EXPLICIT[ROOTPERSIST]:-}" && -n "${SANDBOX_ROOTPERSIST:-}" ]] && OPT_ROOTPERSIST="$SANDBOX_ROOTPERSIST"
  [[ -z "${CLI_EXPLICIT[DIAG]:-}" && -n "${SANDBOX_DIAG:-}" ]] && OPT_DIAG="$SANDBOX_DIAG"
  [[ -z "${CLI_EXPLICIT[DEBUG]:-}" && -n "${SANDBOX_DEBUG:-}" ]] && OPT_DEBUG="$SANDBOX_DEBUG"
  [[ -z "${CLI_EXPLICIT[NWJS_NATIVE]:-}" && -n "${SANDBOX_NWJS_NATIVE:-}" ]] && OPT_NWJS_NATIVE="$SANDBOX_NWJS_NATIVE"
  [[ -n "${SANDBOX_RUNNER:-}" ]] && GAME_SANDBOX_RUNNER="$SANDBOX_RUNNER"
fi

NWJS_BIN_CACHE="$CACHE/sandbox/nwjs.path"

resolve_nwjs_bin() {
  if [[ -n "${NWJS_BIN:-}" && -x "$NWJS_BIN" ]]; then
    printf '%s\n' "$NWJS_BIN"; return 0
  fi
  if command -v nw >/dev/null 2>&1; then
    command -v nw; return 0
  fi
  if [[ -f "$NWJS_BIN_CACHE" ]]; then
    local cached
    cached="$(<"$NWJS_BIN_CACHE")"
    [[ -x "$cached" ]] && { printf '%s\n' "$cached"; return 0; }
  fi
  command -v nix >/dev/null 2>&1 || return 1
  local out
  out="$(nix eval --raw nixpkgs#nwjs.outPath 2>/dev/null)" || out=""
  [[ -n "$out" && -x "$out/bin/nw" ]] || return 1
  mkdir -p "${NWJS_BIN_CACHE%/*}"
  printf '%s\n' "$out/bin/nw" > "$NWJS_BIN_CACHE"
  printf '%s\n' "$out/bin/nw"
}

preflight_target() {
  local t="$1" size a
  size="$(stat -c %s -- "$t" 2>/dev/null || echo 0)"

  if [[ "$size" -eq 0 ]]; then
    sandbox_log ERROR "refusing to launch: $NAME is 0 bytes."
    sandbox_log ERROR "that is almost always an unfinished or failed archive extraction."
    local -a archives=()
    while IFS= read -r -d '' a; do archives+=("$a"); done < <(
      find "$PROG_DIR" -maxdepth 1 -type f \
        \( -iname '*.rar' -o -iname '*.7z' -o -iname '*.zip' \
           -o -iname '*.tar' -o -iname '*.tar.*' -o -iname '*.tgz' \) -print0 2>/dev/null
    )
    if (( ${#archives[@]} > 0 )); then
      for a in "${archives[@]}"; do
        sandbox_log ERROR "archive next to it: ${a##*/}"
      done
      sandbox_log ERROR "extract it first, e.g.: unrar x '${archives[0]}'"
    fi
    exit 1
  fi

  if ! is_plausible_executable "$t"; then
    sandbox_log ERROR "refusing to launch: $NAME does not look like a valid executable."
    sandbox_log ERROR "first bytes: $(head -c 4 -- "$t" 2>/dev/null | od -An -tc | tr -s ' ')"
    exit 1
  fi
}

preflight_target "$TARGET"

if [[ "${NAME,,}" == "nw.exe" && -e "$PROG_DIR/package.nw" && ! -s "$PROG_DIR/package.nw" ]]; then
  sandbox_log ERROR "refusing to launch: package.nw is empty (failed extraction)."
  exit 1
fi

# ENV runner resolution
ENV_RUNNER_DIR=""
ENV_RUNNER_TYPE=""
if [[ -n "${GAME_SANDBOX_RUNNER:-}" ]]; then
  if ENV_RUNNER_DIR="$(resolve_env_runner "$GAME_SANDBOX_RUNNER" 2>/dev/null)"; then
    ENV_RUNNER_TYPE="${GAME_SANDBOX_RUNNER%%/*}"
    sandbox_log INFO "using ENV runner: $ENV_RUNNER_DIR"
  else
    sandbox_log WARN "ENV runner not found for $GAME_SANDBOX_RUNNER"
  fi
fi

NWJS_MODE=0
if [[ "${NAME,,}" == "nw.exe" && -e "$PROG_DIR/package.nw" && "$OPT_NWJS_NATIVE" == "1" ]]; then
  if NWJS_BIN="$(resolve_nwjs_bin 2>/dev/null)"; then
    NWJS_MODE=1
    sandbox_log INFO "NW.js bundle - using native NW.js ($NWJS_BIN)"
  else
    sandbox_log WARN "NW.js bundle - native NW.js unavailable, falling back to wine."
  fi
fi

sandbox_log INFO "launching $NAME"
sandbox_log INFO "from: $PROG_DIR (mounted as /program)"

UNITY_ARGS=()
if [[ "$OPT_UNITY_JOBS" == "1" ]]; then
  stem="${NAME%.*}"
  if [[ -d "$PROG_DIR/${stem}_Data" ]]; then
    cores=$(nproc 2>/dev/null || echo 2)
    workers=$(( cores - 1 ))
    [[ $workers -lt 1 ]] && workers=1
    UNITY_ARGS=(-job-worker-count "$workers")
    sandbox_log INFO "unity-style entry detected - ${UNITY_ARGS[*]}"
  fi
fi

if [[ -n "$ENV_RUNNER_DIR" && "$ENV_RUNNER_TYPE" == "nwjs" ]]; then
  NWJS_MODE=1
  NWJS_BIN="/env/bin/nw"
  NAME="nw"
  RUNNER=("$NWJS_BIN" "/home/player/app" "${UNITY_ARGS[@]}")
  sandbox_log INFO "NW.js bundle - using ENV native NW.js ($NWJS_BIN)"
elif [[ "$NWJS_MODE" == "1" ]]; then
  NAME="nw"
  RUNNER=("$NWJS_BIN" "/home/player/app" "${UNITY_ARGS[@]}")
else
  case "${NAME,,}" in
    *.exe|*.msi|*.bat|*.cmd)
      if [[ -n "$ENV_RUNNER_DIR" && "$ENV_RUNNER_TYPE" == "wine" ]]; then
        WINE_BIN="/env/bin/wine"
        sandbox_log INFO "using ENV wine: $WINE_BIN"
        RUNNER=("$WINE_BIN" "./$NAME" "${UNITY_ARGS[@]}")
      elif [[ -n "$ENV_RUNNER_DIR" && "$ENV_RUNNER_TYPE" == "electron" ]]; then
        if [[ -x "$ENV_RUNNER_DIR/electron" ]]; then
          ELEC_BIN="$ENV_RUNNER_DIR/electron"
        elif [[ -x "$ENV_RUNNER_DIR/bin/electron" ]]; then
          ELEC_BIN="$ENV_RUNNER_DIR/bin/electron"
        else
          ELEC_BIN="$(find "$ENV_RUNNER_DIR" -maxdepth 4 -name electron -type f -executable 2>/dev/null | head -n1)"
        fi
        if [[ -n "$ELEC_BIN" ]]; then
          sandbox_log INFO "using ENV electron: $ELEC_BIN"
          if [[ -f "$PROG_DIR/resources/app.asar" ]]; then
            RUNNER=("$ELEC_BIN" "/program/resources/app.asar" "${UNITY_ARGS[@]}")
          elif [[ -d "$PROG_DIR/resources/app" ]]; then
            RUNNER=("$ELEC_BIN" "/program/resources/app" "${UNITY_ARGS[@]}")
          elif [[ -f "$PROG_DIR/app.asar" ]]; then
            RUNNER=("$ELEC_BIN" "/program/app.asar" "${UNITY_ARGS[@]}")
          else
            RUNNER=("$ELEC_BIN" "/program" "${UNITY_ARGS[@]}")
          fi
        else
          RUNNER=(wine "./$NAME" "${UNITY_ARGS[@]}")
        fi
      else
        RUNNER=(wine "./$NAME" "${UNITY_ARGS[@]}")
      fi
      ;;
    *) RUNNER=("./$NAME" "${UNITY_ARGS[@]}") ;;
  esac
fi

is_cef_bundle() {
  [[ -e "$1/libcef.so" || -e "$1/icudtl.dat" || -e "$1/resources.pak" ]] && return 0
  local f
  for f in "$1"/chrome_*.pak; do [[ -e "$f" ]] && return 0; done
  return 1
}

# Chromium Wine stability flags injection
need_chromium_wine_flags=0
if [[ -n "${ENV_RUNNER_TYPE:-}" && "$ENV_RUNNER_TYPE" == "electron" ]]; then
  :
elif [[ "${NAME,,}" == *.exe ]]; then
  if is_cef_bundle "$PROG_DIR" || [[ "${NAME,,}" == *"electron"* ]] || [[ -f "$PROG_DIR/icudtl.dat" && -f "$PROG_DIR/libcef.so" ]]; then
    need_chromium_wine_flags=1
  fi
fi

if [[ "${need_chromium_wine_flags:-0}" == "1" && "${RUNNER[0],,}" == *"wine"* ]]; then
  RUNNER+=(--no-sandbox --disable-gpu-sandbox --in-process-gpu --disable-direct-composition --ignore-gpu-blocklist)
  sandbox_log INFO "applied Chromium GPU stability flags for CEF/Electron under Wine"
fi

# ---------------------------------------------------------------------------
# Extra native runtime libs
# ---------------------------------------------------------------------------
NATIVE_LIBS_CACHE="$CACHE/sandbox/native-libs.path"

resolve_native_extra_libs() {
  if [[ -f "$NATIVE_LIBS_CACHE" ]]; then
    local cached
    cached="$(<"$NATIVE_LIBS_CACHE")"
    [[ -e "$cached/lib/libnss3.so" ]] && { printf '%s\n' "$cached"; return 0; }
  fi
  command -v nix-build >/dev/null 2>&1 || return 1
  sandbox_log INFO "realising extra native libs (nss/nspr), first run only..."
  local store
  store="$(nix-build --no-out-link -E '
    with import <nixpkgs> {};
    symlinkJoin {
      name = "sandbox-native-libs";
      paths = [ nss nspr ];
    }
  ' 2>/dev/null | tail -n1)" || return 1
  [[ -e "$store/lib/libnss3.so" ]] || return 1
  mkdir -p "${NATIVE_LIBS_CACHE%/*}"
  printf '%s\n' "$store" > "$NATIVE_LIBS_CACHE"
  printf '%s\n' "$store"
}

# ---------------------------------------------------------------------------
# NixOS dynamic linker resolution
# ---------------------------------------------------------------------------
NIXLD_ARGS=()
NATIVE_ENV=()
case "${NAME,,}" in
  *.exe|*.msi|*.bat|*.cmd) : ;;
  *)
    fhs=""
    sr="$(readlink -f "$(command -v steam-run 2>/dev/null)" 2>/dev/null || true)"
    [[ -n "$sr" ]] && fhs="$(grep -oE '/nix/store/[a-z0-9]+-[a-z0-9.-]*fhsenv-rootfs' "$sr" | head -n1)"
    [[ -n "$fhs" && ! -d "$fhs/usr/lib64" ]] && fhs=""

    ld=""
    if [[ -n "$fhs" && -e "$fhs/usr/lib64/ld-linux-x86-64.so.2" ]]; then
      ld="$fhs/usr/lib64/ld-linux-x86-64.so.2"
    else
      ld="$(ldd "$(command -v bash)" 2>/dev/null | grep -o '/nix/store/.*ld-linux-x86-64.so.2' | head -n1 || true)"
    fi

    extra_libs=""
    if is_cef_bundle "$PROG_DIR"; then
      epath="$(resolve_native_extra_libs || true)"
      if [[ -n "$epath" ]]; then
        extra_libs="$epath/lib:"
        sandbox_log INFO "CEF/NW.js bundle - adding nss/nspr from $epath/lib"
      fi
    fi

    if [[ -n "$ld" ]]; then
      NIXLD_ARGS=(--ro-bind "$ld" /lib64/ld-linux-x86-64.so.2)
      libs="${extra_libs}/run/opengl-driver/lib:/run/opengl-driver-32/lib:${ld%/*}:/run/current-system/sw/lib${fhs:+:$fhs/usr/lib64}"
      NATIVE_ENV=(--setenv LD_LIBRARY_PATH "$libs" --setenv SANDBOX_NATIVE 1)
      sandbox_log INFO "native target - binding glibc loader${fhs:+ + steam-run FHS libs}"
    else
      sandbox_log WARN "warning - no glibc loader found, native launch may fail"
    fi

    if [[ "$OPT_X11" != "1" ]] && is_cef_bundle "$PROG_DIR"; then
      RUNNER+=(--ozone-platform=wayland)
      NATIVE_ENV+=(--setenv XDG_SESSION_TYPE wayland)
      NATIVE_ENV+=(--setenv NIXOS_OZONE_WL 1)
      sandbox_log INFO "CEF/NW.js bundle - forcing wayland ozone platform"
    fi
    ;;
esac

ENV_MOUNTS=()
if [[ -n "${ENV_RUNNER_DIR:-}" && -d "$ENV_RUNNER_DIR" ]]; then
  ENV_MOUNTS=(--ro-bind "$ENV_RUNNER_DIR" /env)
  NATIVE_ENV+=(--setenv PATH "/env/bin:/env:/run/current-system/sw/bin:/program")
  if [[ -z "${LD_LIBRARY_PATH:-}" ]]; then
    NATIVE_ENV+=(--setenv LD_LIBRARY_PATH "/env/lib:/env/lib64")
  else
    NATIVE_ENV+=(--setenv LD_LIBRARY_PATH "/env/lib:/env/lib64:${LD_LIBRARY_PATH}")
  fi
  if [[ "${ENV_RUNNER_TYPE:-}" == "wine" ]]; then
    NATIVE_ENV+=(--setenv WINEPREFIX "/home/player/.wine")
  fi
  sandbox_log INFO "mounting ENV runner at /env"
fi

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAYLAND_SOCK="${WAYLAND_DISPLAY:-wayland-0}"

# ---------------------------------------------------------------------------
# Toggles -> bwrap args
# ---------------------------------------------------------------------------
EXTRA_ARGS=()
SEED_ARGS=()
DIR_ARGS=()
X11_ARGS=()
DISPLAY_ARGS=()
NV_PRIME_ENV=()
DIAG_ENV=()
DEBUG_ENV=()

[[ "$OPT_INPUT" == "1" ]] && EXTRA_ARGS+=(--dev-bind-try /dev/input /dev/input)

if [[ "$OPT_WRITE_DIR" == "1" ]]; then
  DIR_ARGS=(--bind "$PROG_DIR" /program)
else
  DIR_ARGS=(--ro-bind "$PROG_DIR" /program)
fi

if [[ "$OPT_X11" == "1" ]]; then
  X11_ARGS=(--bind-try /tmp/.X11-unix /tmp/.X11-unix)
  DISPLAY_ARGS=(--setenv DISPLAY :0)
fi

if [[ -c /dev/nvidia0 ]]; then
  NV_PRIME_ENV=(
    --setenv __NV_PRIME_RENDER_OFFLOAD 1
    --setenv __GLX_VENDOR_LIBRARY_NAME nvidia
  )
  EGL_JSONS="/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json:/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
  if [[ -f /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json ]]; then
    NV_PRIME_ENV+=(--setenv __EGL_VENDOR_LIBRARY_FILENAMES "$EGL_JSONS")
  fi
fi

[[ "$OPT_DIAG" == "1" ]] && DIAG_ENV=(--setenv SANDBOX_DIAG 1)

if [[ "$OPT_DEBUG" == "1" ]]; then
  DEBUG_ENV=(
    --setenv LIBGL_DEBUG verbose
    --setenv EGL_LOG_LEVEL debug
    --setenv MESA_LOG_LEVEL debug
    --setenv VK_LOADER_DEBUG info
  )
fi

if [[ ! -d "$TEMPLATE/drive_c/windows/system32" ]]; then
  sandbox_log INFO "first run - building wine prefix template (~30s)..."
  rm -rf "$TEMPLATE"
  mkdir -p "${TEMPLATE%/*}"
  WINEDEBUG=-all WINEPREFIX="$TEMPLATE" wineboot -u >/dev/null 2>&1
  if [[ ! -d "$TEMPLATE/drive_c/windows/system32" ]]; then
    sandbox_log ERROR "failed to build prefix template"
    exit 1
  fi
  WINEPREFIX="$TEMPLATE" wineserver -k 2>/dev/null || true
  sleep 1
fi

if [[ "$OPT_PERSIST" == "1" ]]; then
  if [[ ! -d "$PROG_DIR/.wine-sandbox/drive_c/windows/system32" ]]; then
    sandbox_log INFO "seeding new persistent prefix from template..."
    rm -rf "$PROG_DIR/.wine-sandbox"
    cp -a --reflink=auto "$TEMPLATE" "$PROG_DIR/.wine-sandbox"
  fi
  EXTRA_ARGS+=(--bind "$PROG_DIR/.wine-sandbox" /home/player/.wine)
  sandbox_log INFO "note - wine prefix persists in $PROG_DIR/.wine-sandbox"
  sandbox_log INFO "use --ephemeral (or [t] in the picker) to run this launch fresh instead."
else
  SEED_ARGS=(--ro-bind "$TEMPLATE" /mnt/wine-template)
fi

# ---------------------------------------------------------------------------
# Root-level saves
# ---------------------------------------------------------------------------
ROOT_PERSIST_DEFAULT="/savedata /save /saves /SaveData /SavedGames /home/player/.renpy"
ROOT_PERSIST_ALL="${ROOT_PERSIST_DEFAULT}${SANDBOX_ROOT_PATHS:+ ${SANDBOX_ROOT_PATHS}}"
STORE_ARGS=()
ROOT_PATHS_ENV=()

if [[ "$OPT_ROOTPERSIST" == "1" ]]; then
  if [[ "$OPT_PERSIST" == "1" ]]; then
    ROOT_STORE="$PROG_DIR/.sandbox-rootfs"
    mkdir -p "$ROOT_STORE"

    LEGACY_SAVE="$PROG_DIR/.wine-sandbox/drive_c/savedata"
    if [[ -e "$LEGACY_SAVE" && ! -e "$ROOT_STORE/_savedata" ]]; then
      mv "$LEGACY_SAVE" "$ROOT_STORE/_savedata"
    fi

    STORE_ARGS=(--bind "$ROOT_STORE" /mnt/rootstore)
    ROOT_PATHS_ENV=(--setenv ROOT_PERSIST_PATHS "$ROOT_PERSIST_ALL")
    sandbox_log INFO "note - root-level saves persist in $ROOT_STORE"
    sandbox_log INFO "watching:${ROOT_PERSIST_ALL// /  }"
  else
    sandbox_log INFO "note - ephemeral run: root-level saves will not persist."
  fi
fi

if [[ "$OPT_WRITE_DIR" != "1" ]]; then
  sandbox_log INFO "note - target folder is read-only this run."
  sandbox_log INFO "use --write-dir (or [t] in the picker) if it saves next to its own executable."
fi

# ---------------------------------------------------------------------------
# Seccomp filter extraction with persistent caching
# ---------------------------------------------------------------------------
find_libseccomp() {
  local p bits cls magic
  bits="$(python3 -c 'import struct; print(struct.calcsize("P") * 8)' 2>/dev/null || echo 64)"
  cls=02; [[ "$bits" == 32 ]] && cls=01
  if command -v ldconfig >/dev/null 2>&1; then
    p="$(ldconfig -p 2>/dev/null | awk '/libseccomp\.so\.2([[:space:]]|$)/{print $NF; exit}')"
    [[ -n "$p" && -e "$p" ]] && { printf '%s\n' "$p"; return 0; }
  fi
  for p in /nix/store/*libseccomp-*-lib/lib/libseccomp.so.2 /nix/store/*-libseccomp-*/lib/libseccomp.so.2; do
    [[ -e "$p" ]] || continue
    magic="$(head -c 5 -- "$p" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
    [[ "$magic" == "7f454c46$cls" ]] || continue
    printf '%s\n' "$p"; return 0
  done
  return 1
}

SECCOMP_ARGS=()
SECCOMP_CACHE_DIR="$CACHE/sandbox"
SECCOMP_CACHE="$SECCOMP_CACHE_DIR/seccomp.bpf"
mkdir -p "$SECCOMP_CACHE_DIR"

if [[ "$OPT_SECCOMP" == "1" ]]; then
  if [[ -f "$SECCOMP_CACHE" && "$SECCOMP_CACHE" -nt "$0" ]]; then
    sandbox_log INFO "using cached seccomp BPF blob: $SECCOMP_CACHE"
    exec 200<"$SECCOMP_CACHE"
    SECCOMP_ARGS=(--seccomp 200)
  elif command -v python3 >/dev/null 2>&1; then
    SECCOMP_BPF="$(mktemp "${RUNTIME}/sandbox-seccomp.XXXXXX")"
    SECCOMP_LIB="$(find_libseccomp || true)"

    if python3 - "$SECCOMP_BPF" "$SECCOMP_LIB" <<'PYEOF' 2>/dev/null
import ctypes, ctypes.util, os, sys

out_path = sys.argv[1]
candidates = []
if len(sys.argv) > 2 and sys.argv[2]:
    candidates.append(sys.argv[2])
candidates.append(ctypes.util.find_library("seccomp") or "libseccomp.so.2")

lib = None
for libname in candidates:
    try:
        lib = ctypes.CDLL(libname)
        break
    except OSError:
        continue
if lib is None:
    sys.exit(1)

SCMP_ACT_ALLOW = 0x7fff0000
EPERM = 1
SCMP_ACT_ERRNO_EPERM = 0x00050000 | EPERM

lib.seccomp_init.restype = ctypes.c_void_p
lib.seccomp_init.argtypes = [ctypes.c_uint32]
lib.seccomp_syscall_resolve_name.restype = ctypes.c_int
lib.seccomp_syscall_resolve_name.argtypes = [ctypes.c_char_p]
lib.seccomp_rule_add.restype = ctypes.c_int
lib.seccomp_rule_add.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
lib.seccomp_export_bpf.restype = ctypes.c_int
lib.seccomp_export_bpf.argtypes = [ctypes.c_void_p, ctypes.c_int]
lib.seccomp_release.argtypes = [ctypes.c_void_p]

ctx = lib.seccomp_init(SCMP_ACT_ALLOW)
if not ctx: sys.exit(1)

SCMP_ARCH_X86_64 = 0xc000003e
SCMP_ARCH_X86 = 0x40000003
lib.seccomp_arch_native.restype = ctypes.c_uint32
lib.seccomp_arch_add.restype = ctypes.c_int
lib.seccomp_arch_add.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
if lib.seccomp_arch_native() == SCMP_ARCH_X86_64:
    lib.seccomp_arch_add(ctx, SCMP_ARCH_X86)

DENY = [
    "ptrace",
    "kexec_load", "kexec_file_load",
    "init_module", "finit_module", "delete_module", "create_module", "query_module",
    "mount", "umount2", "umount", "pivot_root", "chroot",
    "swapon", "swapoff", "reboot", "syslog", "acct", "quotactl", "nfsservctl",
    "bpf", "userfaultfd", "perf_event_open",
    "add_key", "request_key", "keyctl",
    "open_by_handle_at", "name_to_handle_at",
    "setns", "iopl", "ioperm", "modify_ldt",
    "get_kernel_syms", "sysfs", "uselib", "vm86", "vm86old",
]

added = 0
for name in DENY:
    nr = lib.seccomp_syscall_resolve_name(name.encode())
    if nr != -1 and lib.seccomp_rule_add(ctx, SCMP_ACT_ERRNO_EPERM, nr, 0) == 0:
        added += 1

if added == 0:
    lib.seccomp_release(ctx)
    sys.exit(1)

fd = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
rc = lib.seccomp_export_bpf(ctx, fd)
os.close(fd)
lib.seccomp_release(ctx)
sys.exit(0 if rc == 0 else 1)
PYEOF
    then
      cp "$SECCOMP_BPF" "$SECCOMP_CACHE" 2>/dev/null || true
      exec 200<"$SECCOMP_BPF"
      rm -f "$SECCOMP_BPF"
      SECCOMP_ARGS=(--seccomp 200)
      sandbox_log INFO "built and cached seccomp filter: $SECCOMP_CACHE"
    else
      sandbox_log WARN "seccomp filter skipped (libseccomp unavailable)."
      rm -f "$SECCOMP_BPF"
    fi
  else
    sandbox_log WARN "seccomp filter skipped (python3 not found)."
  fi
else
  sandbox_log INFO "seccomp filter disabled."
fi

# ---------------------------------------------------------------------------
# Visual Window Color Verification Helper
# ---------------------------------------------------------------------------
verify_window_color() {
  local title="$1"
  command -v grim >/dev/null 2>&1 || return 0
  sleep 4
  local geom
  geom=$(niri msg windows 2>/dev/null | awk -F'"' "/\"$title\"/{found=1} found && /geometry:/{print \$2; exit}" || true)
  if [[ -n "$geom" ]]; then
    local tmp_img="/tmp/sandbox-verify-$$.png"
    grim -g "$geom" "$tmp_img" 2>/dev/null || return 0
    if command -v convert >/dev/null 2>&1; then
      local pixel
      pixel=$(convert "$tmp_img" -format '%[pixel:u.p{50%,50%}]' info: 2>/dev/null || true)
      if [[ "$pixel" == *"255,255,255"* || "$pixel" == *"white"* ]]; then
        sandbox_log WARN "visual check warning: window for '$title' appears pure white!"
      else
        sandbox_log INFO "visual check passed for '$title' (pixel color: $pixel)"
      fi
    fi
    rm -f "$tmp_img"
  fi
}

if [[ "$OPT_DIAG" == "1" ]]; then
  verify_window_color "$NAME" &
fi

# ---------------------------------------------------------------------------
# Host-side Wine Server Cleanup & Trap
# ---------------------------------------------------------------------------
cleanup() {
  if [[ "$OPT_PERSIST" == "1" && -d "$PROG_DIR/.wine-sandbox" ]]; then
    WINEPREFIX="$PROG_DIR/.wine-sandbox" wineserver -k 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Execution via bwrap
# ---------------------------------------------------------------------------
EXIT_CODE=0
setsid --wait bwrap \
  "${SECCOMP_ARGS[@]}" \
  --unshare-all --unshare-user --disable-userns \
  --new-session \
  --die-with-parent \
  --clearenv \
  --proc /proc \
  --ro-bind-try /sys/class/drm /sys/class/drm \
  --ro-bind-try /sys/dev/char /sys/dev/char \
  --ro-bind-try /sys/devices /sys/devices \
  --ro-bind-try /sys/bus/pci /sys/bus/pci \
  --dev /dev \
  --dev-bind-try /dev/dri /dev/dri \
  --dev-bind-try /dev/nvidia0 /dev/nvidia0 \
  --dev-bind-try /dev/nvidiactl /dev/nvidiactl \
  --dev-bind-try /dev/nvidia-modeset /dev/nvidia-modeset \
  --dev-bind-try /dev/nvidia-uvm /dev/nvidia-uvm \
  --dev-bind-try /dev/nvidia-uvm-tools /dev/nvidia-uvm-tools \
  --dev-bind-try /dev/nvidia-caps /dev/nvidia-caps \
  --ro-bind-try /nix/store /nix/store \
  --ro-bind-try /run/opengl-driver /run/opengl-driver \
  --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32 \
  --ro-bind-try /run/current-system/sw /run/current-system/sw \
  --tmpfs /tmp \
  --tmpfs /etc \
  --ro-bind-try /etc/fonts /etc/fonts \
  --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig \
  --ro-bind-try /etc/egl /etc/egl \
  --ro-bind-try /etc/glvnd /etc/glvnd \
  --ro-bind-try /etc/vulkan /etc/vulkan \
  --ro-bind-try /etc/OpenCL /etc/OpenCL \
  --symlink /run/current-system/sw/bin/bash /bin/sh \
  "${X11_ARGS[@]}" \
  "${ENV_MOUNTS[@]}" \
  --perms 0700 --dir "$RUNTIME" \
  --bind-try "$RUNTIME/$WAYLAND_SOCK" "$RUNTIME/$WAYLAND_SOCK" \
  --bind-try "$RUNTIME/pulse" "$RUNTIME/pulse" \
  --bind-try "$RUNTIME/pipewire-0" "$RUNTIME/pipewire-0" \
  "${DIR_ARGS[@]}" \
  --chdir /program \
  --tmpfs /home/player \
  "${EXTRA_ARGS[@]}" \
  "${SEED_ARGS[@]}" \
  "${STORE_ARGS[@]}" \
  "${NIXLD_ARGS[@]}" \
  "${DIAG_ENV[@]}" \
  "${DEBUG_ENV[@]}" \
  --setenv HOME /home/player \
  --setenv WINEPREFIX /home/player/.wine \
  --setenv WINEDEBUG -all \
  --setenv PATH "/run/current-system/sw/bin:/program" \
  --setenv XDG_RUNTIME_DIR "$RUNTIME" \
  --setenv XDG_CONFIG_HOME /home/player/.config \
  --setenv XDG_CACHE_HOME /home/player/.cache \
  --setenv XDG_DATA_DIRS "/run/current-system/sw/share:/run/opengl-driver/share:/run/opengl-driver-32/share" \
  --setenv WAYLAND_DISPLAY "$WAYLAND_SOCK" \
  "${DISPLAY_ARGS[@]}" \
  "${NV_PRIME_ENV[@]}" \
  --setenv DXVK_STATE_CACHE_PATH 'C:\dxvk-cache' \
  "${ROOT_PATHS_ENV[@]}" \
  "${NATIVE_ENV[@]}" \
  $( [[ "$NWJS_MODE" == "1" ]] && printf -- '--setenv NWJS_MODE 1 --setenv NWJS_BIN %s ' "$NWJS_BIN" ) \
  -- /bin/sh -c '
    echo "00000000000000000000000000000000" > /etc/machine-id

    if [[ "${SANDBOX_DIAG:-0}" == "1" ]]; then
      echo "=== Sandbox Graphics Diagnostics ===" >&2
      echo "[>] Checking /dev/dri:" >&2
      ls -la /dev/dri 2>&1 | sed "s/^/    /" >&2 || echo "    /dev/dri NOT present!" >&2
      echo "[>] Checking Vulkan ICD manifests:" >&2
      ls -la /etc/vulkan/icd.d/ /run/opengl-driver/share/vulkan/icd.d/ 2>&1 | sed "s/^/    /" >&2 || true
      echo "[>] Checking fontconfig cache/output:" >&2
      if command -v fc-match >/dev/null 2>&1; then
        echo "    fc-match sans -> $(fc-match sans 2>&1)" >&2
        echo "    fc-list count -> $(fc-list 2>/dev/null | wc -l)" >&2
      else
        echo "    fc-match not on PATH" >&2
      fi
      echo "====================================" >&2
    fi

    if [[ -d /mnt/wine-template ]]; then
      cp -a --reflink=auto /mnt/wine-template /home/player/.wine
    fi
    mkdir -p /home/player/.wine/drive_c/dxvk-cache

    if [[ "${NWJS_MODE:-0}" == "1" && -e /program/package.nw ]]; then
      echo "sandbox: preparing package.nw in /home/player/app..." >&2
      mkdir -p /home/player/app
      if [[ -d /program/package.nw ]]; then
        cp -a /program/package.nw/* /home/player/app/
      elif command -v unzip >/dev/null 2>&1; then
        unzip -q /program/package.nw -d /home/player/app
      else
        cp -a /program/package.nw /home/player/app/
      fi
    fi

    persist_copy_in() {
      local p s
      for p in ${ROOT_PERSIST_PATHS:-}; do
        s="/mnt/rootstore/${p//\//_}"
        if [[ -e "$s" ]]; then
          mkdir -p "${p%/*}"
          rm -rf "$p"
          cp -a "$s" "$p"
        fi
      done
    }
    persist_copy_out() {
      local p s
      for p in ${ROOT_PERSIST_PATHS:-}; do
        if [[ -e "$p" ]]; then
          s="/mnt/rootstore/${p//\//_}"
          rm -rf "$s"
          cp -a "$p" "$s"
        fi
      done
    }

    persist_copy_in
    trap persist_copy_out EXIT
    trap "exit 130" INT
    trap "exit 143" TERM HUP

    if [[ "${SANDBOX_NATIVE:-0}" == "1" ]]; then
      shopt -s nullglob
      for d in /program/lib/*/ /program/lib64 /program/lib; do
        LD_LIBRARY_PATH="$d:$LD_LIBRARY_PATH"
      done
      export LD_LIBRARY_PATH
    fi

    "$@"
    exit $?
  ' sh "${RUNNER[@]}" "$@" || EXIT_CODE=$?

sandbox_log INFO "$NAME exited with code $EXIT_CODE"
if [[ $EXIT_CODE -ne 0 ]]; then
  sandbox_log WARN "non-zero exit ($EXIT_CODE) - check logs for details"
fi

exit $EXIT_CODE