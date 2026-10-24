{ config, ... }:

{
  xdg.configFile = {
    "my-scripts/startapps.sh" = {
      source = ../shared/my-scripts/startapps.sh;
      force = true;
    };
    "my-scripts/toggles-power.sh" = {
      source = ../shared/my-scripts/toggles-power.sh;
      force = true;
    };
    "my-scripts/toggles-save.sh" = {
      source = ../shared/my-scripts/toggles-save.sh;
      force = true;
    };
  };

  home.activation.copyRogConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/rog/rog-control-center.cfg" ] || [ -L "$HOME/.config/rog/rog-control-center.cfg" ]; then
      mkdir -p "$HOME/.config/rog"
      cp -f "${../shared/rog/rog-control-center.cfg}" "$HOME/.config/rog/rog-control-center.cfg"
      chmod 644 "$HOME/.config/rog/rog-control-center.cfg"
    fi
  '';
}
