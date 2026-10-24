{
  home.file.".local/share/nautilus/scripts/Open in Yazi" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      uri="''${NAUTILUS_SCRIPT_CURRENT_URI:-file://$PWD}"
      dir="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1].removeprefix("file://")))' "$uri")"

      if [ -n "''${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
        dir="$(dirname "$(printf '%s\n' "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)")"
      fi

      exec ghostty --working-directory="$dir" -e yazi
    '';
  };

  home.file.".local/share/nautilus/scripts/Open Terminal Here" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      uri="''${NAUTILUS_SCRIPT_CURRENT_URI:-file://$PWD}"
      dir="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1].removeprefix("file://")))' "$uri")"

      if [ -n "''${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
        dir="$(dirname "$(printf '%s\n' "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)")"
      fi

      exec ghostty --working-directory="$dir"
    '';
  };
}
