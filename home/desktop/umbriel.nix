{ pkgs, ... }:

let
  # Umbriel ships a usable default config but does not autostart a shell.
  # Keep this minimal; add settings here as we learn what we want to tweak.
  settings = {
    general.autostart = [ "noctalia" ];
  };
in
{
  xdg.configFile."umbriel/config.toml" = {
    source = (pkgs.formats.toml { }).generate "umbriel-config.toml" settings;
    force = true;
  };
}
