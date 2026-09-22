#!/usr/bin/env bash
# sandbox.sh - run an untrusted program in a hardened bubblewrap box
#
# usage: sandbox.sh                        interactive picker over the library
#        sandbox.sh soulslike/             picker over LIB/soulslike
#        sandbox.sh /any/other/dir         picker over that dir directly
#        sandbox.sh /path/to/program.exe   launch that file directly (wine)
#        sandbox.sh /path/to/native-bin    launch that file directly (native)
#
# Flags (can appear before or after the path, in any order):
#   --write-dir / --read-only-dir      program's own folder rw / ro (default: ro)
#   --persist / --ephemeral            keep wine prefix / wipe on exit (default: persist)
#   --x11 / --wayland                  allow X11 socket / Wayland only (default: wayland)
#   --input / --no-input               pass /dev/input through (default: no)
#   --seccomp / --no-seccomp           enable/disable the syscall deny-list (default: on)
#   --no-job-tuning                    don't pass -job-worker-count to Unity-style builds
#   --root-persist / --no-root-persist persist root-level saves (/savedata etc.)
#   --diag / --no-diag                 one-shot startup graphics diagnostic (default: on)
#   --debug / --no-debug               verbose Mesa/EGL/Vulkan runtime logging (default: off)
#   -h / --help                        print this usage and exit

set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
TEMPLATE="$CACHE/sandbox/wine-template"
LIB="/mnt/origin/games/SailingSeas"      # <-- hardcoded default library root

print_usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# toggle state - defaults from env vars, overridable by flags and UI
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

# ---------------------------------------------------------------------------
# flag parsing
# ---------------------------------------------------------------------------
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --write-dir)       OPT_WRITE_DIR=1 ;;
    --read-only-dir)   OPT_WRITE_DIR=0 ;;
    --persist)         OPT_PERSIST=1 ;;
    --ephemeral)       OPT_PERSIST=0 ;;
    --x11)             OPT_X11=1 ;;
    --wayland)         OPT_X11=0 ;;
    --input)           OPT_INPUT=1 ;;
    --no-input)        OPT_INPUT=0 ;;
    --seccomp)         OPT_SECCOMP=1 ;;
    --no-seccomp)      OPT_SECCOMP=0 ;;
    --no-job-tuning)   OPT_UNITY_JOBS=0 ;;
    --root-persist)    OPT_ROOTPERSIST=1 ;;
    --no-root-persist) OPT_ROOTPERSIST=0 ;;
    --diag)            OPT_DIAG=1 ;;
    --no-diag)         OPT_DIAG=0 ;;
    --debug)           OPT_DEBUG=1 ;;
    --no-debug)        OPT_DEBUG=0 ;;
    -h|--help)         print_usage; exit 0 ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
      break
      ;;
    -*)
      echo "sandbox: unknown flag: $1" >&2
      echo "         run with --help to see available flags." >&2
      exit 1
      ;;
    *) POSITIONAL+=("$1") ;;
  esac
  shift
done
set -- "${POSITIONAL[@]}"

# ---------------------------------------------------------------------------
# picker
# ---------------------------------------------------------------------------
JUNK_EXE_PATTERNS=(
  '*crashhandler*' '*crash-handler*' '*crash_reporter*' '*crashpad*'
  '*ue4prereqsetup*' '*ueprereqsetup*' '*vc_redist*' '*vcredist*'
  '*dxsetup*' '*directx*' '*dotnet*' '*unins*' '*setup*' '*installer*'
  '*battleye*' '*easyanticheat*' '*eac_launcher*'
)

find_candidate_exe() {
  local args=(find "$1" -maxdepth "$2" -type f -iname '*.exe')
  for pat in "${JUNK_EXE_PATTERNS[@]}"; do
    args+=(-not -iname "$pat")
  done
  "${args[@]}" -printf '%s\t%p\n' 2>/dev/null | sort -rn | awk -F'\t' 'NR==1{print $2}'
}

scan_programs() {
  [[ -d "$1" ]] || return 0
  local base exe dirs d

  exe="$(find_candidate_exe "$1" 1)"
  [[ -n "$exe" ]] && printf '%s\t%s\n' "${1##*/}" "$exe"

  mapfile -d '' dirs < <(find "$1" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
  for d in "${dirs[@]}"; do
    base="${d##*/}"
    [[ "$base" == .* || "$base" == *.part ]] && continue
    exe="$(find_candidate_exe "$d" 1)"
    [[ -n "$exe" ]] && printf '%s\t%s\n' "$base" "$exe"
  done
}

onoff() { [[ "$1" == "1" ]] && echo "on" || echo "off"; }

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
    echo " [b] back"
    printf '> '
    read -r -n1 key || return 0
    echo
    case "$key" in
      1) OPT_WRITE_DIR=$(( 1 - OPT_WRITE_DIR )) ;;
      2) OPT_PERSIST=$(( 1 - OPT_PERSIST )) ;;
      3) OPT_X11=$(( 1 - OPT_X11 )) ;;
      4) OPT_INPUT=$(( 1 - OPT_INPUT )) ;;
      5) OPT_SECCOMP=$(( 1 - OPT_SECCOMP )) ;;
      6) OPT_UNITY_JOBS=$(( 1 - OPT_UNITY_JOBS )) ;;
      7) OPT_ROOTPERSIST=$(( 1 - OPT_ROOTPERSIST )) ;;
      8) OPT_DIAG=$(( 1 - OPT_DIAG )) ;;
      9) OPT_DEBUG=$(( 1 - OPT_DEBUG )) ;;
      b|B) return 0 ;;
    esac
  done
}

menu() {
  local -a names=() exes=()
  local name exe key i

  while true; do
    names=(); exes=()
    while IFS=$'\t' read -r name exe; do
      names+=("$name"); exes+=("$exe")
    done < <(scan_programs "$1")

    echo
    [[ ${#names[@]} -eq 0 ]] && echo "no entries found in: $1" >&2

    for ((i=0; i<${#names[@]}; i++)); do
      printf '[%d] - %s\n' "$((i + 1))" "${names[i]}"
    done

    echo "[t] - toggles"
    echo "[r] - refresh"
    echo "[q] - quit"
    printf 'entry number> '

    read -r key || exit 0
    case "$key" in
      "") continue ;;
      q|Q) exit 0 ;;
      r|R) continue ;;
      t|T) toggles_menu; continue ;;
      [1-9]|[1-9][0-9]|[1-9][0-9][0-9])
        if [[ "$key" -ge 1 && "$key" -le "${#exes[@]}" ]] 2>/dev/null; then
          LAUNCH_TARGET="${exes[$((key - 1))]}"; return 0
        fi
        echo "sandbox: no such entry: $key" >&2
        ;;
      *) echo "sandbox: huh? ($key)" >&2 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# target resolution
# ---------------------------------------------------------------------------
LAUNCH_TARGET=""
if [[ $# -eq 0 ]]; then
  menu "$LIB"
  TARGET="$(readlink -f "$LAUNCH_TARGET")"
elif [[ -d "$1" ]]; then
  menu "$(readlink -f "$1")"
  TARGET="$(readlink -f "$LAUNCH_TARGET")"
  shift
elif [[ -d "$LIB/${1%/}" ]]; then
  menu "$(readlink -f "$LIB/${1%/}")"
  TARGET="$(readlink -f "$LAUNCH_TARGET")"
  shift
else
  TARGET="$(readlink -f "$1")"
  shift
fi

[[ -f "$TARGET" ]] || { echo "sandbox: no such file: $TARGET" >&2; exit 1; }

PROG_DIR="$(dirname "$TARGET")"
NAME="${TARGET##*/}"
echo "sandbox: launching $NAME" >&2
echo "         from: $PROG_DIR (mounted as /program)" >&2

UNITY_ARGS=()
if [[ "$OPT_UNITY_JOBS" == "1" ]]; then
  stem="${NAME%.*}"
  if [[ -d "$PROG_DIR/${stem}_Data" ]]; then
    cores=$(nproc 2>/dev/null || echo 2)
    workers=$(( cores - 1 ))
    [[ $workers -lt 1 ]] && workers=1
    UNITY_ARGS=(-job-worker-count "$workers")
    echo "sandbox: unity-style entry detected - ${UNITY_ARGS[*]}" >&2
  fi
fi

case "${NAME,,}" in
  *.exe|*.msi|*.bat|*.cmd) RUNNER=(wine "./$NAME" "${UNITY_ARGS[@]}") ;;
  *)                       RUNNER=("./$NAME" "${UNITY_ARGS[@]}")      ;;
esac

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

    if [[ -n "$ld" ]]; then
      NIXLD_ARGS=(--ro-bind "$ld" /lib64/ld-linux-x86-64.so.2)
      libs="/run/opengl-driver/lib:/run/opengl-driver-32/lib:${ld%/*}:/run/current-system/sw/lib${fhs:+:$fhs/usr/lib64}"
      NATIVE_ENV=(--setenv LD_LIBRARY_PATH "$libs" --setenv SANDBOX_NATIVE 1)
      echo "sandbox: native target - binding glibc loader${fhs:+ + steam-run FHS libs}" >&2
    else
      echo "sandbox: warning - no glibc loader found, native launch may fail" >&2
    fi
    ;;
esac

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAYLAND_SOCK="${WAYLAND_DISPLAY:-wayland-0}"

# ---------------------------------------------------------------------------
# toggles -> bwrap args
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

# One-shot startup check (cheap - runs once, then gets out of the way).
[[ "$OPT_DIAG" == "1" ]] && DIAG_ENV=(--setenv SANDBOX_DIAG 1)

# Verbose Mesa/EGL/Vulkan *runtime* logging. Off by default: these are
# not one-time startup messages, some of Mesa's debug paths log
# synchronously on a per-call basis and can cost real frame time.
# Turn on only while actively chasing a graphics problem.
if [[ "$OPT_DEBUG" == "1" ]]; then
  DEBUG_ENV=(
    --setenv LIBGL_DEBUG verbose
    --setenv EGL_LOG_LEVEL debug
    --setenv MESA_LOG_LEVEL debug
    --setenv VK_LOADER_DEBUG info
  )
fi

if [[ ! -d "$TEMPLATE/drive_c/windows/system32" ]]; then
  echo "sandbox: first run - building wine prefix template (~30s)..." >&2
  rm -rf "$TEMPLATE"
  mkdir -p "${TEMPLATE%/*}"
  WINEDEBUG=-all WINEPREFIX="$TEMPLATE" wineboot -u >/dev/null 2>&1
  if [[ ! -d "$TEMPLATE/drive_c/windows/system32" ]]; then
    echo "sandbox: failed to build prefix template" >&2
    exit 1
  fi
  WINEPREFIX="$TEMPLATE" wineserver -k 2>/dev/null || true
  sleep 1
fi

if [[ "$OPT_PERSIST" == "1" ]]; then
  if [[ ! -d "$PROG_DIR/.wine-sandbox/drive_c/windows/system32" ]]; then
    echo "sandbox: seeding new persistent prefix from template..." >&2
    rm -rf "$PROG_DIR/.wine-sandbox"
    cp -a --reflink=auto "$TEMPLATE" "$PROG_DIR/.wine-sandbox"
  fi
  EXTRA_ARGS+=(--bind "$PROG_DIR/.wine-sandbox" /home/player/.wine)
  echo "sandbox: note - wine prefix persists in $PROG_DIR/.wine-sandbox" >&2
  echo "         use --ephemeral (or [t] in the picker) to run this launch fresh instead." >&2
else
  SEED_ARGS=(--ro-bind "$TEMPLATE" /mnt/wine-template)
fi

# ---------------------------------------------------------------------------
# root-level saves
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
    echo "sandbox: note - root-level saves persist in $ROOT_STORE" >&2
    echo "         watching:${ROOT_PERSIST_ALL// /  }" >&2
  else
    echo "sandbox: note - ephemeral run: root-level saves will not persist." >&2
  fi
fi

if [[ "$OPT_WRITE_DIR" != "1" ]]; then
  echo "sandbox: note - target folder is read-only this run." >&2
  echo "         use --write-dir (or [t] in the picker) if it saves next to its own executable." >&2
fi

# ---------------------------------------------------------------------------
# seccomp filter extraction
# ---------------------------------------------------------------------------
SECCOMP_ARGS=()
if [[ "$OPT_SECCOMP" == "1" ]] && command -v python3 >/dev/null 2>&1; then
  SECCOMP_BPF="$(mktemp "${RUNTIME}/sandbox-seccomp.XXXXXX")"

  if python3 - "$SECCOMP_BPF" <<'PYEOF' 2>/dev/null
import ctypes, ctypes.util, os, sys

out_path = sys.argv[1]
libname = ctypes.util.find_library("seccomp") or "libseccomp.so.2"
lib = ctypes.CDLL(libname)

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

DENY = [
    "ptrace", "process_vm_readv", "process_vm_writev",
    "kexec_load", "kexec_file_load",
    "init_module", "finit_module", "delete_module", "create_module", "query_module",
    "mount", "umount2", "umount", "pivot_root", "chroot",
    "swapon", "swapoff", "reboot", "syslog", "acct", "quotactl", "nfsservctl",
    "bpf", "userfaultfd", "perf_event_open",
    "add_key", "request_key", "keyctl",
    "open_by_handle_at", "name_to_handle_at",
    "setns", "iopl", "ioperm", "modify_ldt",
    "get_kernel_syms", "sysfs", "uselib", "vm86", "vm86old", "kcmp",
    "process_madvise",
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
    exec 200<"$SECCOMP_BPF"
    rm -f "$SECCOMP_BPF"
    SECCOMP_ARGS=(--seccomp 200)
  else
    echo "sandbox: note - seccomp filter skipped (libseccomp unavailable)." >&2
    rm -f "$SECCOMP_BPF"
  fi
else
  if [[ "$OPT_SECCOMP" == "0" ]]; then
    echo "sandbox: note - seccomp filter disabled." >&2
  else
    echo "sandbox: note - seccomp filter skipped (python3 not found)." >&2
  fi
fi

exec bwrap \
  "${SECCOMP_ARGS[@]}" \
  --unshare-all --unshare-user --disable-userns \
  --new-session --die-with-parent \
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
  ' sh "${RUNNER[@]}" "$@"
