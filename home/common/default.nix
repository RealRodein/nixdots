{ pkgs, machineName, ... }:

let
  isOrbiter = machineName == "orbiter";
  fileManager =
    if isOrbiter then "nautilus.desktop" else "com.system76.CosmicFiles.desktop";
in
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

      function y
        set tmp (mktemp -t yazi-cwd.XXXXXX)
        yazi $argv --cwd-file="$tmp"
        if set cwd (cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
          cd -- "$cwd"
        end
        rm -f -- "$tmp"
      end
    '';

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -lah --icons --git";
      lt = "eza --tree --level=2 --icons";
      cat = "bat --style=plain --paging=never";
      lg = "lazygit";
    };
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.lazygit.enable = true;

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
    EDITOR = "nano";
    VISUAL = "nano";
    PAGER = "less";
    BROWSER = "firefox";
    TERMINAL = "ghostty";
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "RealRodein";
      user.email = "rodein.personal@gmail.com";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      merge.conflictStyle = "zdiff3";
      delta = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };
  };

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = fileManager;

      "application/pdf" = "org.pwmt.zathura.desktop";

      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";

      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";

      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
    };

    associations.added = {
      "inode/directory" = fileManager;

      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "chromium-browser.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
    };
  };

  xdg.configFile = {
    # Browsers and some desktop services rewrite mimeapps.list when they start,
    # which replaces the managed symlink. Keep the generated copy authoritative.
    "mimeapps.list".force = true;

    "my-scripts/sandbox.sh" = {
      source = ../shared/my-scripts/sandbox.sh;
      force = true;
    };
    "my-scripts/sync-flatpak-steam-icons.sh" = {
      source = ../shared/my-scripts/sync-flatpak-steam-icons.sh;
      force = true;
    };

    "MangoHud/MangoHud.conf".source = ../shared/mangohud/MangoHud.conf;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-enable-primary-paste = true;
    };
  };

  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}
