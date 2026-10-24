{ config, pkgs, ... }:

{
  xdg.configFile = {
    "niri/config.kdl" = {
      source = ../shared/niri/config.kdl;
      force = true;
    };
    "niri/config.d/autostart.kdl" = {
      source = ../shared/niri/config.d/autostart.kdl;
      force = true;
    };
    "niri/config.d/decorations.kdl" = {
      source = ../shared/niri/config.d/decorations.kdl;
      force = true;
    };
    "niri/config.d/devices.kdl" = {
      source = ../shared/niri/config.d/devices.kdl;
      force = true;
    };
    "niri/config.d/keybinds.kdl" = {
      source = ../shared/niri/config.d/keybinds.kdl;
      force = true;
    };
    "niri/config.d/rules.kdl" = {
      source = ../shared/niri/config.d/rules.kdl;
      force = true;
    };
    "niri/config.d/focus-or-spawn.sh" = {
      source = ../shared/niri/config.d/focus-or-spawn.sh;
      force = true;
    };
    "niri/config.d/close-or-tab.sh" = {
      source = ../shared/niri/config.d/close-or-tab.sh;
      force = true;
    };

    "systemd/user/niri.service.d/ld-library-path.conf" = {
      force = true;
      text = ''
        [Service]
        Environment=LD_LIBRARY_PATH=${pkgs.gcc.cc.lib}/lib:${pkgs.zlib}/lib
      '';
    };
  };

  home.activation.copyOutputsConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    SRC="${../shared/niri/config.d/outputs-orbiter.kdl}"
    DST="$HOME/.config/niri/config.d/outputs.kdl"
    mkdir -p "$(dirname "$DST")"
    if [ -f "$SRC" ]; then
      cp -f "$SRC" "$DST"
    fi
  '';
}
