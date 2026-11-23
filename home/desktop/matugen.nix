{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;

  refresh = pkgs.writeShellScript "matugen-refresh" ''
    set -euo pipefail

    xfconf_query="${pkgs.xfconf}/bin/xfconf-query"
    wallpaper=""

    # XFCE stores the current wallpaper in the xfce4-desktop xfconf channel.
    # Property names vary with the monitor, so search all backdrop properties.
    for property in $($xfconf_query -c xfce4-desktop -l 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E '/(image-path|last-image)$' || true); do
      candidate="$($xfconf_query -c xfce4-desktop -p "$property" 2>/dev/null || true)"
      if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        wallpaper="$candidate"
        break
      fi
    done

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
      wallpaper="$(${pkgs.findutils}/bin/find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f 2>/dev/null | ${pkgs.coreutils}/bin/head -n1 || true)"
    fi

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
      echo "matugen-refresh: no wallpaper found; skipping theme refresh" >&2
      exit 0
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/matugen/themes"

    if ! ${pkgs.matugen}/bin/matugen image "$wallpaper" -m dark --source-color-index 0; then
      echo "matugen-refresh: matugen failed for $wallpaper" >&2
      exit 1
    fi
  '';
in
{
  home.packages = [ pkgs.matugen ];

  gtk.gtk3.extraCss = "@import url(\"matugen.css\");";
  gtk.gtk4.extraCss = "@import url(\"matugen.css\");";

  # Old matugen wrote straight to gtk.css. Let Home Manager replace those stale
  # regular files; theme colors now live in the imported matugen.css instead.
  xdg.configFile."gtk-3.0/gtk.css".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  xdg.configFile = {
    "matugen/config.toml".text = ''
      [config]
      version_check = false

      [templates.ghostty]
      input_path = '${home}/.config/matugen/templates/ghostty'
      output_path = '${home}/.config/ghostty/themes/matugen'

      [templates.btop]
      input_path = '${home}/.config/matugen/templates/btop.theme'
      output_path = '${home}/.config/btop/themes/matugen.theme'

      [templates.gtk3]
      input_path = '${home}/.config/matugen/templates/gtk.css'
      output_path = '${home}/.config/gtk-3.0/matugen.css'

      [templates.gtk4]
      input_path = '${home}/.config/matugen/templates/gtk.css'
      output_path = '${home}/.config/gtk-4.0/matugen.css'

      [templates.zed]
      input_path = '${home}/.config/matugen/templates/zed.json'
      output_path = '${home}/.config/zed/themes/matugen.json'

      [templates.zathura]
      input_path = '${home}/.config/matugen/templates/zathura'
      output_path = '${home}/.config/zathura/matugen'
    '';

    "matugen/templates/ghostty".source = ../shared/matugen/templates/ghostty;
    "matugen/templates/btop.theme".source = ../shared/matugen/templates/btop.theme;
    "matugen/templates/gtk.css".source = ../shared/matugen/templates/gtk.css;
    "matugen/templates/zed.json".source = ../shared/matugen/templates/zed.json;
    "matugen/templates/zathura".source = ../shared/matugen/templates/zathura;
  };

  systemd.user.services.matugen-refresh = {
    Unit.Description = "Regenerate wallpaper-derived theme";
    Service = {
      Type = "oneshot";
      ExecStart = "${refresh}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.paths.matugen = {
    Unit.Description = "Watch the XFCE wallpaper setting";
    Path = {
      PathChanged = "${home}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml";
      Unit = "matugen-refresh.service";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.matugen = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/matugen/themes"
    if ! ${refresh}; then
      echo "matugen: initial theme refresh failed; it will retry when the wallpaper changes (systemctl --user status matugen-refresh.service)" >&2
    fi
  '';
}
