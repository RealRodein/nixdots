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
      "my-scripts/vm-usb-toggle.sh".source = ./shared/my-scripts/vm-usb-toggle.sh;

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
          Environment=LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib:${pkgs.zlib}/lib
        '';
        force = true;
      };
    })
    (lib.mkIf (machineName == "railjack") {
      "kglobalshortcutsrc" = {
        source = ./shared/kde/kglobalshortcutsrc;
        force = true;
      };
    })
  ];

  home.file = lib.mkIf (machineName == "railjack") {
    ".var/app/org.vinegarhq.Sober/config/sober/config.json" = {
      source = ./shared/sober/config.json;
      force = true;
    };
    ".local/share/applications/launch-ghostty.desktop" = {
      source = ./shared/kde/applications/launch-ghostty.desktop;
      force = true;
    };
    ".local/share/applications/launch-zen.desktop" = {
      source = ./shared/kde/applications/launch-zen.desktop;
      force = true;
    };
    ".local/share/applications/launch-nemo.desktop" = {
      source = ./shared/kde/applications/launch-nemo.desktop;
      force = true;
    };
    ".local/share/applications/launch-steam.desktop" = {
      source = ./shared/kde/applications/launch-steam.desktop;
      force = true;
    };
    ".local/share/applications/launch-vesktop.desktop" = {
      source = ./shared/kde/applications/launch-vesktop.desktop;
      force = true;
    };
    ".local/share/applications/launch-zed.desktop" = {
      source = ./shared/kde/applications/launch-zed.desktop;
      force = true;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-enable-primary-paste = true;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
    };
    associations.added = {
      "inode/directory" = "thunar.desktop";
    };
  };

  home.activation.ensureNoctaliaSymlinks = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ "${machineName}" = "orbiter" ]; then
      mkdir -p "$HOME/.local/state/noctalia"
      if [ ! -L "$HOME/.local/state/noctalia/settings.toml" ] && [ ! -e "$HOME/.local/state/noctalia/settings.toml" ]; then
        ln -s "$HOME/NixDOTs/home/${machineName}/dotfiles/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
      fi
      if [ ! -L "$HOME/.local/state/noctalia/logos" ] && [ ! -d "$HOME/.local/state/noctalia/logos" ]; then
        ln -s "$HOME/NixDOTs/home/${machineName}/dotfiles/noctalia/logos" "$HOME/.local/state/noctalia/logos"
      fi
    fi
  '';

  home.activation.copyOutputsConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ "${machineName}" = "orbiter" ]; then
      HOST="${machineName}"
      SRC="$HOME/NixDOTs/home/shared/niri/config.d/outputs-$HOST.kdl"
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