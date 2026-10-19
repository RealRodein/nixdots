{ config, pkgs, lib, machineName, ... }:

{
  home.username = "rodein";
  home.homeDirectory = "/home/rodein";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    initExtra = ''
      if [ -f "$(command -v fish)" ]; then
        exec fish
      fi
    '';
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
  };

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  gtk = {
    enable = true;

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-color-scheme = "prefer-dark";
    };
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "RealRodein";
      user.email = "rodein.personal@gmail.com";
    };
  };

  xdg.configFile = lib.mkMerge [
    {
      "my-scripts/startapps.sh" = {
        source = ./shared/my-scripts/startapps.sh;
        force = true;
      };

      "my-scripts/toggles-power.sh" = {
        source = ./shared/my-scripts/toggles-power.sh;
        force = true;
      };
      "my-scripts/toggles-save.sh" = {
        source = ./shared/my-scripts/toggles-save.sh;
        force = true;
      };
      "my-scripts/yazi-portal.sh".source = ./shared/my-scripts/yazi-portal.sh;
      "my-scripts/sandbox.sh" = {
        source = ./shared/my-scripts/sandbox.sh;
        force = true;
      };
      "my-scripts/sync-flatpak-steam-icons.sh".source = ./shared/my-scripts/sync-flatpak-steam-icons.sh;

      "yazi/yazi.toml".source = ./shared/yazi/yazi.toml;
      "yazi/keymap.toml".source = ./shared/yazi/keymap.toml;
      "yazi/init.lua".source = ./shared/yazi/init.lua;
      "yazi/open-pdf-in-terminal.sh".source = ./shared/yazi/open-pdf-in-terminal.sh;
      "yazi/plugins/context-menu.yazi/main.lua".source = ./shared/yazi/plugins/context-menu.yazi/main.lua;

      "ghostty/config".source = ./shared/ghostty/config;
      "ghostty/titlebar-sync.sh".source = ./shared/ghostty/titlebar-sync.sh;

      "btop/btop.conf".source = ./shared/btop/btop.conf;

      "zed/settings.json" = {
        source = ./shared/zed/settings.json;
        force = true;
      };

      "MangoHud/MangoHud.conf".source = ./shared/mangohud/MangoHud.conf;

      # Firefox-family browsers (Zen) and Vesktop register themselves in
      # ~/.config/mimeapps.list as soon as they start, which replaces the managed
      # symlink and aborts the next activation. force = true keeps the managed
      # copy authoritative; the generated file itself comes from xdg.mimeApps.
      "mimeapps.list" = {
        force = true;
      };
    }
    (lib.mkIf (machineName == "orbiter") {
      "niri/config.kdl" = {
        source = ./shared/niri/config.kdl;
        force = true;
      };
      "niri/config.d/autostart.kdl" = {
        source = ./shared/niri/config.d/autostart.kdl;
        force = true;
      };
      "niri/config.d/decorations.kdl" = {
        source = ./shared/niri/config.d/decorations.kdl;
        force = true;
      };
      "niri/config.d/devices.kdl" = {
        source = ./shared/niri/config.d/devices.kdl;
        force = true;
      };
      "niri/config.d/keybinds.kdl" = {
        source = ./shared/niri/config.d/keybinds.kdl;
        force = true;
      };

      "niri/config.d/rules.kdl" = {
        source = ./shared/niri/config.d/rules.kdl;
        force = true;
      };
      "niri/config.d/focus-or-spawn.sh" = {
        source = ./shared/niri/config.d/focus-or-spawn.sh;
        force = true;
      };
      "niri/config.d/close-or-tab.sh" = {
        source = ./shared/niri/config.d/close-or-tab.sh;
        force = true;
      };

      # Extend the package-provided niri.service (which has ExecStart etc.) with a
      # drop-in that exports libstdc++.so.6 / libz.so.1 to the niri session. Pip-built
      # wheels (numpy/onnxruntime) in plugin venvs (e.g. wallpaper_depth) need these to
      # resolve their native libs on NixOS; all noctalia/plugin processes niri spawns
      # inherit this env (autostart + keybinds). Scoped to the session, not global.
      "systemd/user/niri.service.d/ld-library-path.conf" = {
        text = ''
          [Service]
          Environment=LD_LIBRARY_PATH=/nix/store/0c857z3y2kwn0dyaqp6f5mqwnbj49cvj-gcc-15.2.0-lib/lib:${pkgs.zlib}/lib
        '';
        force = true;
      };
    })
    (lib.mkIf (machineName == "railjack") {
      # fontconfig rewrites its own conf.d entries whenever the cache is
      # refreshed, which collides with the one Home Manager links in. Force it
      # so the activation cannot abort on an unrelated font change.
      "fontconfig/conf.d/10-hm-fonts.conf" = {
        force = true;
      };

      # Super-key shortcut for the start menu applet. cosmic-settings rewrites
      # this file whenever a custom shortcut is added in its UI, which would
      # clobber the managed symlink - force it like mimeapps.list above.
      #
      # Must be the modifier-only form (no key): cosmic-comp compares the
      # modifier state *after* the keypress, so (modifiers: [], key: "Super_L")
      # never matches a bare Super press, and keyless bindings fire on the
      # modifier's release. Being equal in modifiers+key, this entry replaces
      # the default (modifiers: [Super]): System(Launcher) on merge.
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
        force = true;
        text = ''
          {
          (modifiers: [Super]): Spawn("/run/current-system/sw/bin/cosmic-start-menu-applet --toggle"),
          }
        '';
      };
    })
  ];

  home.file = lib.mkMerge [
    (lib.mkIf (machineName == "railjack") {
      ".local/share/icons/hicolor/scalable/apps/com.system76.CosmicPanelLauncherButton.svg".source =
        ./orbiter/dotfiles/noctalia/logos/nix-snowflake-white.svg;
      ".local/share/icons/hicolor/scalable/apps/com.system76.CosmicLauncher.svg".source =
        ./orbiter/dotfiles/noctalia/logos/nix-snowflake-white.svg;
    })
  ];

  # GTK2 apps (and anything going through the GTK2 theme engine) read
  # ~/.gtkrc-2.0, which the GTK libraries rewrite whenever a theme is picked in
  # their own settings dialog. That clobbered the symlink and made the Home
  # Manager activation fail, so the file has to be force-overwritten.
  gtk.gtk2.force = lib.mkIf (machineName == "railjack") true;

  # Ghostty is the terminal of this machine, so it has to answer the
  # XDG Terminal Execution spec for anything that asks for "the default terminal"
  # (file managers, portals, Flatpak apps).
  xdg.terminal-exec = lib.mkIf (machineName == "railjack") {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-enable-primary-paste = true;
    };
  };

  # Directory default: Thunar on orbiter, COSMIC Files on railjack.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" =
      if machineName == "orbiter" then "thunar.desktop" else "com.system76.CosmicFiles.desktop";
    associations.added = {
      "inode/directory" =
        if machineName == "orbiter" then "thunar.desktop" else "com.system76.CosmicFiles.desktop";

      # Zen and Vesktop register these themselves the first time they run, which
      # is what wrote the previous live mimeapps.list. Declaring them keeps the
      # associations in place right after an activation instead of waiting for the
      # next browser start.
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "text/html" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
    };
  };

  # Noctalia keeps its state under ~/.local/state, not ~/.config, so it is
  # symlinked into the repo instead of being declared as an xdg.configFile.
  # Only orbiter runs a Noctalia shell (under niri), and it owns
  # home/orbiter/dotfiles/noctalia.
  home.activation.ensureNoctaliaSymlinks = lib.mkIf (machineName == "orbiter") (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      DOTS="$HOME/nixdots/home/${machineName}/dotfiles/noctalia"
      mkdir -p "$HOME/.local/state/noctalia"

      link() {
        local src="$1" dst="$2"
        if [ -L "$dst" ] && [ "$(readlink "$dst")" != "$src" ]; then
          rm -f "$dst"
        fi
        if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
          ln -s "$src" "$dst"
        fi
      }

      link "$DOTS/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
      link "$DOTS/logos" "$HOME/.local/state/noctalia/logos"
    ''
  );

  home.activation.copyOutputsConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ "${machineName}" = "orbiter" ]; then
      HOST="${machineName}"
      SRC="$HOME/nixdots/home/shared/niri/config.d/outputs-$HOST.kdl"
      DST="$HOME/.config/niri/config.d/outputs.kdl"
      mkdir -p "$(dirname "$DST")"
      if [ -f "$SRC" ]; then
        cp -f "$SRC" "$DST"
      fi
    fi
  '';

  home.activation.copyRogConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ "${machineName}" = "orbiter" ]; then
      if [ ! -f "$HOME/.config/rog/rog-control-center.cfg" ] || [ -L "$HOME/.config/rog/rog-control-center.cfg" ]; then
        mkdir -p "$HOME/.config/rog"
        cp -f "${./shared/rog/rog-control-center.cfg}" "$HOME/.config/rog/rog-control-center.cfg"
        chmod 644 "$HOME/.config/rog/rog-control-center.cfg"
      fi
    fi
  '';

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}