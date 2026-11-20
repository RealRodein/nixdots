{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;
  cosmicSettings = "${pkgs.cosmic-settings}/bin/cosmic-settings";

  refresh = pkgs.writeShellScript "matugen-refresh" ''
    set -euo pipefail

    background_config="$HOME/.config/cosmic/com.system76.CosmicBackground/v1/all"
    wallpaper=""

    if [ -f "$background_config" ]; then
      wallpaper="$(sed -n 's/.*source: Path("\([^"]*\)").*/\1/p' "$background_config" | head -n1)"
    fi

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
      wallpaper="$(${pkgs.findutils}/bin/find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f 2>/dev/null | head -n1 || true)"
    fi

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
      echo "matugen-refresh: no wallpaper found; skipping theme refresh" >&2
      exit 0
    fi

    mkdir -p "$HOME/.config/matugen/themes"

    if ! ${pkgs.matugen}/bin/matugen image "$wallpaper" -m dark --source-color-index 0; then
      echo "matugen-refresh: matugen failed for $wallpaper" >&2
      exit 1
    fi

    if [ -x "${cosmicSettings}" ] && [ -f "$HOME/.config/matugen/themes/cosmic.ron" ]; then
      if ! ${cosmicSettings} appearance import "$HOME/.config/matugen/themes/cosmic.ron"; then
        echo "matugen-refresh: COSMIC theme import failed" >&2
        exit 1
      fi
    fi
  '';
in
{
  home.packages = [ pkgs.matugen ];

  gtk.gtk3.extraCss = "@import url(\"matugen.css\");";
  gtk.gtk4.extraCss = "@import url(\"matugen.css\");";

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

      [templates.cosmic]
      input_path = '${home}/.config/matugen/templates/cosmic_theme.ron'
      output_path = '${home}/.config/matugen/themes/cosmic.ron'
    '';

    "matugen/templates/ghostty".source = ../shared/matugen/templates/ghostty;
    "matugen/templates/btop.theme".source = ../shared/matugen/templates/btop.theme;
    "matugen/templates/gtk.css".source = ../shared/matugen/templates/gtk.css;
    "matugen/templates/zed.json".source = ../shared/matugen/templates/zed.json;
    "matugen/templates/zathura".source = ../shared/matugen/templates/zathura;
    "matugen/templates/cosmic_theme.ron".source =
      ../shared/matugen/templates/cosmic_theme.ron;
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
    Unit.Description = "Watch the COSMIC wallpaper setting";
    Path = {
      PathChanged = "${home}/.config/cosmic/com.system76.CosmicBackground/v1/all";
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
