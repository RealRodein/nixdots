{ pkgs, inputs, ... }:

let
  luciolePkg = inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Declarative base config. Luciole keeps GUI changes in settings.toml, so
  # rebuilding never clobbers preferences set from its Settings dialog.
  xdg.configFile."luciole/config.toml".text = ''
    schema_version = 1

    [browser]
    terminal_command = "ghostty"
  '';

  # Noctalia renders Luciole's shipped template into
  # ~/.config/luciole/colors.toml whenever the palette changes. Keep the
  # template itself declarative; the generated output is Luciole-owned.
  xdg.configFile."noctalia/templates/luciole-colors.toml".source =
    "${luciolePkg}/share/luciole/templates/colors.toml";

  xdg.configFile."noctalia/luciole.toml".text = ''
    [theme.templates.user.luciole]
    input_path = "$XDG_CONFIG_HOME/noctalia/templates/luciole-colors.toml"
    output_path = "$XDG_CONFIG_HOME/luciole/colors.toml"
  '';

  # Other file managers may install a service file for the same well-known name.
  # A user-level file takes precedence over XDG_DATA_DIRS, so "Show in folder"
  # opens Luciole.
  home.file.".local/share/dbus-1/services/org.freedesktop.FileManager1.service" = {
    text = ''
      [D-BUS Service]
      Name=org.freedesktop.FileManager1
      Exec=${luciolePkg}/bin/luciole --file-manager-service
    '';
  };

  # Luciole passes selected native paths as arguments; with no selection the
  # working directory is the folder being browsed.
  home.file.".local/share/luciole/scripts/Open in Yazi" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      if [ "$#" -gt 0 ]; then
        dir="$(dirname -- "$1")"
      else
        dir="$PWD"
      fi

      exec ghostty --working-directory="$dir" -e yazi
    '';
  };

  home.file.".local/share/luciole/scripts/Open Terminal Here" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      if [ "$#" -gt 0 ]; then
        dir="$(dirname -- "$1")"
      else
        dir="$PWD"
      fi

      exec ghostty --working-directory="$dir"
    '';
  };
}
