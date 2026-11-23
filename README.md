# NixDOTs

A two-machine NixOS + Home Manager flake. Each host keeps the desktop and workflow that suits it, while sharing the shell, CLI tooling, browsers, media apps, and theme plumbing.

## Hosts

| Host | Machine | Desktop | Theme source |
| --- | --- | --- | --- |
| `orbiter` | ASUS laptop | Niri + Noctalia (Luciole file manager) | Noctalia wallpaper templates |
| `railjack` | Desktop | COSMIC | matugen from the COSMIC wallpaper |

Shared defaults:

- Fish, `yazi`, `btop`, `zed`, `mpv`, `zathura`, `imv`, Firefox, Brave Origin.
- Orbiter additionally has the Moonlight client.
- Railjack additionally runs the Sunshine game-streaming host and Tailscale.
- `nano` is the default editor; Neovim is intentionally not configured.
- GUI file managers: Luciole on orbiter, COSMIC Files on railjack.
- Both file managers have “Open in Yazi” and “Open Terminal Here” integration where available.

## Game streaming

Railjack runs the Sunshine host (`services.sunshine`) and orbiter has the
Moonlight client. Open `https://railjack:47990` once to set the Sunshine
username/password and application entries; those are deliberately left to
Sunshine's web UI. Sunshine uses a capability wrapper (`capSysAdmin`) for
DRM/KMS capture, and its firewall ports are opened automatically. Both hosts
also run Tailscale, so Moonlight can connect over the tailnet.

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
- `hosts/railjack/cosmic.nix` - railjack COSMIC session and greeter.
- `home/common/` - shared Home Manager shell, environment, MIME, and GTK config.
- `home/apps/` - per-application Home Manager modules; `home/apps/default.nix`
  imports the shared set.
- `home/desktop/` - orbiter Niri/Noctalia and railjack COSMIC/matugen modules.
- `home/hosts/<host>.nix` - per-host Home Manager entrypoint. Host-only modules
  are imported here, so adding or removing a host feature is a visible edit.
- `home/shared/` - mutable configs used by Home Manager (Niri, yazi, scripts,
  matugen templates).
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

`home/desktop/matugen.nix` watches COSMIC’s wallpaper setting, runs `matugen` against that image, and imports the generated `cosmic.ron` into COSMIC’s appearance. It also generates:

- Ghostty theme (`matugen`)
- btop theme (`matugen`)
- GTK3/GTK4 colors
- Zed theme (`Matugen`)
- Zathura colors

The watcher is a user-level `systemd.path` unit; activation also runs one initial refresh.
Matugen and the COSMIC theme import now report failures instead of swallowing
them: check `systemctl --user status matugen-refresh.service` if the theme stops
updating. The initial activation refresh only warns, so a first boot without a
wallpaper does not abort the Home Manager generation.

## Add a host

1. Create `hosts/<new-host>/` with `default.nix`, `hardware.nix`, and the rest of the host-local wiring.
2. Import the shared `modules/nixos/...` modules from `hosts/<new-host>/default.nix`.
3. Add `home/hosts/<new-host>.nix` as the Home Manager entrypoint. Import
   `../common`, `../apps`, and only the desktop modules that host needs.
4. Add the flake output in `flake.nix` with `mkHost`, passing both `hostName`
   and `hostPath`.
