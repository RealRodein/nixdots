{ config, lib, pkgs, inputs, ... }:

{
  # Enable the COSMIC Desktop Environment module
  # Use unstable COSMIC packages
  nixpkgs.overlays = [
    (_: prev: let
      up = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
    in {
      inherit (up)
        cosmic-session
        cosmic-greeter
        cosmic-applets
        cosmic-applibrary
        cosmic-bg
        cosmic-comp
        cosmic-files
        cosmic-idle
        cosmic-initial-setup
        cosmic-launcher
        cosmic-notifications
        cosmic-osd
        cosmic-panel
        cosmic-settings
        cosmic-settings-daemon
        cosmic-workspaces-epoch
        cosmic-edit
        cosmic-icons
        cosmic-player
        cosmic-randr
        cosmic-reader
        cosmic-screenshot
        cosmic-term
        cosmic-wallpapers
        cosmic-store
        xdg-desktop-portal-cosmic;
      cosmic-start-menu-applet = prev.rustPlatform.buildRustPackage {
        pname = "cosmic-start-menu-applet";
        version = "0.1.0";
        src = inputs.cosmic-start-menu-applet;
        cargoHash = "sha256-DIo3vTVyvgmTWcytysJs69srBrJD6jLx9L/c9AXC/0A=";

        nativeBuildInputs = [ prev.pkg-config ];
        buildInputs = [
          prev.libxkbcommon
          prev.wayland
          prev.expat
          prev.fontconfig
          prev.freetype
          prev.zlib
        ];

        # wayland-sys is built with its `dlopen` feature, so
        # libwayland-client.so.0 is loaded at runtime instead of being
        # linked. The loader then never sees the wayland store path and
        # winit panics with NoWaylandLib when the panel spawns the applet.
        postFixup = ''
          patchelf --add-rpath ${prev.lib.getLib prev.wayland}/lib $out/bin/cosmic-start-menu-applet
        '';
        postInstall = ''
          install -Dm0644 data/io.github.jjnuthuagen.StartMenu.desktop \
            $out/share/applications/io.github.jjnuthuagen.StartMenu.desktop
          if [ -f data/io.github.jjnuthuagen.StartMenuSettings.desktop ]; then
            install -Dm0644 data/io.github.jjnuthuagen.StartMenuSettings.desktop \
              $out/share/applications/io.github.jjnuthuagen.StartMenuSettings.desktop
          fi

          # The desktop files ask for Icon=start-here-symbolic, which the
          # Cosmic theme resolves to its own four-squares app-grid glyph.
          # Ship the nix flake logo as this app's icon instead and point both
          # entries at it, so launchers and the panel applet list show proper
          # branding. The package's share/icons lands in
          # /run/current-system/sw/share/icons, in every COSMIC process's
          # XDG_DATA_DIRS; Cosmic inherits hicolor, so lookups reach it.
          install -Dm0644 \
            ${../../home/orbiter/dotfiles/noctalia/logos/nix-snowflake-white.svg} \
            $out/share/icons/hicolor/scalable/apps/io.github.jjnuthuagen.StartMenu.svg
          substituteInPlace $out/share/applications/io.github.jjnuthuagen.StartMenu.desktop \
            --replace-fail 'Icon=start-here-symbolic' 'Icon=io.github.jjnuthuagen.StartMenu'
          substituteInPlace $out/share/applications/io.github.jjnuthuagen.StartMenuSettings.desktop \
            --replace-fail 'Icon=start-here-symbolic' 'Icon=io.github.jjnuthuagen.StartMenu'
        '';
      };
    })
  ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # The upstream module registers cosmic-session in
  # services.displayManager.sessionPackages, which is what generates the
  # "cosmic" session desktop file. greetd does not read
  # services.displayManager.defaultSession (that is GDM/lightDM/SDDM only), the
  # greeter offers whatever it finds in XDG_DATA_DIRS, so the name is only
  # pinned here for the module's own session-name assertion.
  services.displayManager.defaultSession = "cosmic";

  # greetd is a systemd service, so it starts with systemd's environment (PATH,
  # LANG, ...) and none of environment.sessionVariables. cosmic-greeter looks
  # its sessions up in $XDG_DATA_DIRS/wayland-sessions; with XDG_DATA_DIRS
  # unset it falls back to /usr/local/share and /usr/share, which do not exist
  # on NixOS - the session list comes up empty and the greeter panics on login
  # ("session \"\" not found"). Hand it the session directory that
  # sessionPackages generated, plus the system share directory for icons.
  systemd.services.greetd.environment.XDG_DATA_DIRS = lib.concatStringsSep ":" [
    "${config.services.displayManager.sessionData.desktops}/share"
    "/run/current-system/sw/share"
  ];

  # Ensure sound and Wayland graphics work smoothly
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # The cosmic.nix module turns geoclue2 on unconditionally (COSMIC ships its
  # own demo agent in cosmic-settings-daemon), so the "no location service"
  # decision has to be forced rather than merely set.
  services.geoclue2.enable = lib.mkForce false;

  # --- Home Manager activation ---
  # With the default (system) service, Home Manager activates rodein's
  # environment from a boot-time system unit that runs *before* the session
  # exists. Any file that an application rewrites in the meantime (GTK's
  # .gtkrc-2.0, fontconfig's 10-hm-fonts.conf, mimeapps.list) then trips
  # Home Manager's collision check, the activation aborts, and the whole
  # generation is silently left unapplied.
  #
  # As a user service it is started by nixos-activation.service at every login,
  # i.e. together with - and after - the session that is going to use it.
  home-manager.startAsUserService = true;
}