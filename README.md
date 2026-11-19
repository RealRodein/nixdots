# NixDOTs

A two-machine NixOS + Home Manager flake. Each host keeps the desktop and workflow that suits it, while sharing the shell, CLI tooling, browsers, media apps, and theme plumbing.

## Hosts

| Host | Machine | Desktop | Theme source |
| --- | --- | --- | --- |
| `orbiter` | ASUS laptop | Umbriel + Noctalia (Niri still installed) | Noctalia wallpaper templates |
| `railjack` | Desktop | COSMIC | matugen from the COSMIC wallpaper |

Shared defaults:

- Fish, `yazi`, `btop`, `zed`, `mpv`, `zathura`, `imv`, Firefox, Chromium.
- `nano` is the default editor; Neovim is intentionally not configured.
- GUI file managers are host-native: Nautilus on orbiter, COSMIC Files on railjack.
- Both file managers have “Open in Yazi” and “Open Terminal Here” integration where available.

## Layout

- `flake.nix` - flake inputs and `orbiter` / `railjack` outputs.
- `lib/mkHost.nix` - shared `nixosSystem` constructor.
- `hosts/<host>/` - host-local hardware, system, user, and package wiring.
- `modules/nixos/packages/cli.nix` - shared CLI stack.
- `modules/nixos/packages/gui.nix` - shared GUI apps.
- `modules/nixos/desktop/noctalia.nix` - orbiter session, greetd, portals, Noctalia.
- `hosts/railjack/cosmic.nix` - railjack COSMIC session and greeter.
- `home/common/` - shared Home Manager shell, environment, MIME, and GTK config.
- `home/apps/` - per-application Home Manager modules.
- `home/desktop/` - orbiter Umbriel/Niri/Noctalia and railjack COSMIC/matugen modules.
- `home/hosts/` - host-specific Home Manager activation and config.
- `home/shared/` - mutable configs used by Home Manager (Niri, yazi, scripts, matugen templates).

## Rebuild

```bash
sudo nixos-rebuild switch --flake ~/nixdots#orbiter
sudo nixos-rebuild switch --flake ~/nixdots#railjack
```

Quick evaluation check:

```bash
nix eval --raw .#nixosConfigurations.orbiter.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.railjack.config.system.build.toplevel.drvPath
```

## Theming

### orbiter

Noctalia generates its built-in templates (btop, Ghostty, GTK, Niri) and community templates (Zed, yazi, lazygit, etc.) from the current wallpaper. Noctalia state is edited directly in:

```text
~/nixdots/home/orbiter/dotfiles/noctalia/
```

Rebuild with `#orbiter` to link that state into `~/.local/state/noctalia`.

### orbiter compositor

Umbriel is the default session (greetd autologin). It and `xdg-desktop-portal-umbriel` come from the `nixpkgs-unstable` flake input; the rest of the system stays on `nixos-26.05`. The generated Umbriel config only autostarts Noctalia and lives in `home/desktop/umbriel.nix` — edit it there, not in `~/.config/umbriel/config.toml`.

Niri is still installed, configured, and registered as a Wayland session. To go back to it as the autologin default, change `services.greetd.settings.default_session.command` in `modules/nixos/desktop/noctalia.nix` to:

```nix
command = "${niriSession}/bin/niri-session";
```

then rebuild with `#orbiter`. `niri-session` can also be run from a TTY while Umbriel is not active.

### railjack

`home/desktop/matugen.nix` watches COSMIC’s wallpaper setting, runs `matugen` against that image, and imports the generated `cosmic.ron` into COSMIC’s appearance. It also generates:

- Ghostty theme (`matugen`)
- btop theme (`matugen`)
- GTK3/GTK4 colors
- Zed theme (`Matugen`)
- Zathura colors

The watcher is a user-level `systemd.path` unit; activation also runs one initial refresh.

## Add a host

1. Create `hosts/<new-host>/` with `default.nix`, `hardware.nix`, and the rest of the host-local wiring.
2. Import the shared `modules/nixos/...` modules and add a Home Manager entrypoint under `home/hosts/`.
3. Add the flake output in `flake.nix` with `mkHost`.
