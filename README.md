# NixDOTs

A two-machine NixOS + Home Manager flake. Each host keeps the desktop and workflow that suits it, while sharing the shell, CLI tooling, browsers, media apps, and theme plumbing.

## Hosts

| Host | Machine | Desktop | Theme source |
| --- | --- | --- | --- |
| `orbiter` | ASUS laptop | Niri + Noctalia (Luciole file manager) | Noctalia wallpaper templates |
| `railjack` | Desktop | Umbriel + Noctalia (Luciole file manager) | Noctalia wallpaper templates |

Shared defaults:

- Fish, `yazi`, `btop`, `zed`, `mpv`, `zathura`, `imv`, Firefox, Brave Origin.
- Orbiter additionally has the Moonlight client.
- Railjack additionally runs the Sunshine game-streaming host and Tailscale.
- `nano` is the default editor; Neovim is intentionally not configured.
- GUI file manager: Luciole on both hosts, with “Open in Yazi” and “Open Terminal Here” integration.

## Game streaming

Railjack runs the Sunshine host (`services.sunshine`) and orbiter has the
Moonlight client. Open `https://railjack:47990` once to set the Sunshine
username/password and application entries; those are deliberately left to
Sunshine's web UI. Sunshine runs as a user graphical-session service and uses a
capability wrapper (`capSysAdmin`), with its firewall ports opened
automatically. Both hosts also run Tailscale, so Moonlight can connect over the
tailnet.

Railjack has two NVIDIA GPUs: the **RTX 3070** (`0000:07:00.0`) drives the
display, the compositor and games, while the **GTX 1050 Ti** (`0000:04:00.0`)
is reserved for NVENC. The wrapper pins the proprietary **580 legacy** driver
(595+ ignores Pascal), sets `CUDA_DEVICE_ORDER=PCI_BUS_ID` and
`CUDA_VISIBLE_DEVICES=0` so CUDA/NVENC picks the 1050 Ti. Keep Sunshine's
`adapter_name` empty — it also selects the capture render node, which must stay
on the 3070. The driver pin only takes effect after a reboot; before that the
running kernel still has the previous driver loaded and NVENC reports
`CUDA_ERROR_SYSTEM_DRIVER_MISMATCH`.

In `~/.config/sunshine/sunshine.conf`, use `capture = portal` and set
`output_name` to the Wayland connector from `umbriel outputs`, not X11's
`HDMI-0`. `xdg-desktop-portal-umbriel` provides the ScreenCast backend;
Sunshine copies the PipeWire frames through system memory and uploads them to
CUDA on the 1050 Ti for NVENC. Sunshine is therefore built with
`cudaSupport = true`; the default nixpkgs build compiles that CUDA upload path
out (`SUNSHINE_ENABLE_CUDA=false`), so portal frames fail in Sunshine's software
converter even though ffmpeg still advertises `h264_nvenc`. The portal node is
backed by the 3070, so Sunshine is also patched to use the system-memory CUDA
path instead of importing its DMA-BUFs into the 1050 Ti (`EGL_BAD_MATCH`,
`0x3009`). Do **not** use `capture = wlr`: Umbriel
deliberately does not advertise `zwlr_export_dmabuf_manager_v1`, which Sunshine
2026.914 requires. KMS capture is also unreliable with the proprietary NVIDIA
driver. The first Moonlight connection may show a portal screencast chooser;
Sunshine saves the restore token in `~/.config/sunshine/portal_token`.

## Layout

- `flake.nix` - flake inputs and `orbiter` / `railjack` outputs. Each output passes
  an explicit `hostName` and `hostPath`.
- `lib/mkHost.nix` - shared `nixosSystem` constructor. It imports
  `home/hosts/<hostName>.nix` as the Home Manager entrypoint.
- `hosts/<host>/` - host-local hardware, system, user, package, and machine quirks.
  - `hosts/orbiter/asus.nix` - ASUS keyboard/Fn keys, wakeup rules, `asusd`.
  - `hosts/orbiter/power.nix` - Intel turbo and `auto-cpufreq` workarounds.
- `modules/nixos/base/boot.nix` - shared boot loader and kernel command line.
- `modules/nixos/base/common.nix` - shared system defaults, including the xkb layout.
- `modules/nixos/hardware/nvidia.nix` - shared NVIDIA defaults; host-specific
  driver packages and PRIME wiring stay in `hosts/<host>/system.nix`.
- `modules/nixos/packages/cli.nix` - shared CLI stack.
- `modules/nixos/packages/gui.nix` - shared GUI apps.
- `modules/nixos/desktop/noctalia.nix` - orbiter session, greetd, portals, Noctalia.
- `hosts/railjack/umbriel.nix` - railjack Umbriel session, greetd autologin,
  portals, XWayland and Luciole.
- `home/common/` - shared Home Manager shell, environment, MIME, and GTK config.
- `home/apps/` - per-application Home Manager modules; `home/apps/default.nix`
  imports the shared set.
- `home/desktop/` - orbiter Niri/Noctalia and railjack Umbriel modules.
- `home/hosts/<host>.nix` - per-host Home Manager entrypoint. Host-only modules
  are imported here, so adding or removing a host feature is a visible edit.
- `home/shared/` - mutable configs used by Home Manager (Niri, yazi, scripts).
- `docs/` - reference material that is not consumed by Nix
  (`docs/niri-options.md` is the local Niri 26.04 option reference).

## Where new settings belong

- Shared NixOS behavior: `modules/nixos/`.
- Machine hardware and unavoidable quirks: `hosts/<host>/`.
- Shared shell/apps: `home/common/` and `home/apps/`.
- Host-specific desktop/app selection: `home/hosts/<host>.nix`.
- Desktop-specific Home Manager config: `home/desktop/`.
- Mutable user state that must be edited live (currently Noctalia
  `settings.toml`): `home/orbiter/dotfiles/noctalia/`.

## Rebuild

```bash
sudo nixos-rebuild switch --flake ~/nixdots#orbiter
sudo nixos-rebuild switch --flake ~/nixdots#railjack
```

Lightweight evaluation check (no build):

```bash
nix flake check --no-build

nix eval --raw .#nixosConfigurations.orbiter.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.railjack.config.system.build.toplevel.drvPath
```

## Discord Rich Presence

- Vesktop is taken from `nixpkgs-unstable` (1.6.9) in
  `modules/nixos/packages/gui.nix`; the 26.05 build (1.6.5) detects far fewer
  games. Keep **Vesktop Settings → Enable Rich Presence via arRPC** enabled.
- Discord also requires **Activity Privacy → Share your detected activities with
  others** to be on; presence will not be shown to others otherwise.
- `PROTON_DISCORD_BRIDGE=1` is set in `home/common/default.nix`. The installed
  GE-Proton 11-1 uses it to expose Discord RPC to Windows games; stock Proton
  ignores it. If a Proton game still shows no activity, force that game to
  GE-Proton in Steam's Compatibility tab.

## Theming

### orbiter

Noctalia generates its built-in templates (btop, Ghostty, GTK, Niri) and community templates (Zed, yazi, lazygit, etc.) from the current wallpaper. Noctalia state is edited directly in:

```text
~/nixdots/home/orbiter/dotfiles/noctalia/
```

Rebuild with `#orbiter` to link that state into `~/.local/state/noctalia`.
`settings.toml` stays a writable symlink into the checkout because Noctalia
rewrites it from its GUI. Its hook commands point at the managed
`~/.config/my-scripts/` and `~/.config/ghostty/` links, so moving the repository
does not break them. The checkout path itself is set in
`home/desktop/noctalia.nix`.

### orbiter compositor

Niri is the default session (greetd autologin). The system stays on `nixos-26.05`; Noctalia comes from `nixpkgs-unstable`, and Luciole from its upstream flake.

Niri's config lives in `home/shared/niri/` and is linked into `~/.config/niri/` by `home/desktop/niri.nix`. The host-specific `config.d/outputs.kdl` is a declarative Home Manager link to `outputs-orbiter.kdl`; there is no activation-time copy. VRR is enabled on `eDP-1`.

Portals are configured in `modules/nixos/desktop/noctalia.nix`: `xdg-desktop-portal-gnome` handles screencasting (required by Niri), `xdg-desktop-portal-gtk` is the fallback, and Luciole provides the file chooser. There is no Secret Service provider — Noctalia's encrypted storage is session-only. Never set `GDK_BACKEND` globally — it breaks the screencast portal.

Luciole's colors are generated by Noctalia from `home/apps/luciole.nix` into `~/.config/luciole/colors.toml` on every theme change; GUI preferences stay writable in `~/.config/luciole/settings.toml`. Luciole is also registered for "Show in folder" via its `org.freedesktop.FileManager1` D-Bus service.

### railjack

Umbriel + Noctalia is the default session with greetd autologin as the account
defined in `lib/user.nix`.
`hosts/railjack/umbriel.nix` enables the compositor from the locked
`nixpkgs-unstable` input (the rest of the machine stays on `nixos-26.05`), the
Umbriel portal, XWayland for Steam/Proton, and Luciole with its FileChooser
portal. `xdg-desktop-portal-umbriel` handles screen capture and global
shortcuts; GTK is the fallback portal. Its screencast chooser is replaced on
this host with a script that always selects HDMI-A-2, so Sunshine never stops
at a share picker when its single-use restore token expires. Orbiter's Noctalia
config is not imported: railjack's Noctalia settings and bar are edited from
its own GUI and stay user-managed.

Railjack runs `sshd` only as a recovery path from orbiter. The firewall accepts
port 22 solely from orbiter's Tailscale address (`100.69.25.98`) and its current
LAN address (`192.168.50.106`); these rules are inserted before the trusted
`tailscale0` rule, so the other Tailscale peer cannot reach SSH. Login is limited
to the same account from `lib/user.nix` by password. Update the LAN address if
orbiter's DHCP lease changes.

`home/desktop/umbriel.nix` writes `~/.config/umbriel/config.toml`: Czech coder
keyboard, Noctalia launcher/control-center/window-switcher keybinds, app
shortcuts (Ghostty, Brave, Luciole, Zed, Yazi), compositor blur/appearance, and
the Noctalia window/layer rules. It also excludes the GTX 1050 Ti from Umbriel's
DRM devices, leaving the 3070 as the sole compositor/capture GPU.
`home/apps/luciole.nix` supplies Luciole's config, its Noctalia color template
and the Yazi/terminal scripts; Luciole is the `inode/directory` default.

Themes come from Noctalia's templates (Ghostty, btop, Luciole colors); Zed uses
`Ayu Dark` and Zathura a static Ayu palette. There is no matugen wallpaper
watcher and no XFCE/Thunar on this host. None of these modules are imported by
orbiter.

## Add a host

1. Create `hosts/<new-host>/` with `default.nix`, `hardware.nix`, and the rest of the host-local wiring.
2. Import the shared `modules/nixos/...` modules from `hosts/<new-host>/default.nix`.
3. Add `home/hosts/<new-host>.nix` as the Home Manager entrypoint. Import
   `../common`, `../apps`, and only the desktop modules that host needs.
4. Add the flake output in `flake.nix` with `mkHost`, passing both `hostName`
   and `hostPath`.
