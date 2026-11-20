{ config, ... }:

{
  imports = [
    ../common
    ../apps
    ../apps/luciole.nix
    ../desktop/niri.nix
    ../desktop/noctalia.nix
  ];

  xdg.configFile = {
    "my-scripts/startapps.sh" = {
      source = ../shared/my-scripts/startapps.sh;
      force = true;
    };
    "my-scripts/toggle-touchpad.sh" = {
      source = ../shared/my-scripts/toggle-touchpad.sh;
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
    "my-scripts/toggle-rog-cc.sh" = {
      source = ../shared/my-scripts/toggle-rog-cc.sh;
      force = true;
    };
    # Wrapper for GameMode + NVIDIA offload + MangoHud. It is orbiter-specific
    # because it relies on PRIME render offload.
    "my-scripts/gamemoderunexec" = {
      source = ../shared/my-scripts/gamemoderunexec;
      force = true;
    };
  };

  # Deliberate exception to declarative config: rog-control-center rewrites its
  # own config file, so seed it once and leave the user's copy writable.
  home.activation.copyRogConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/rog/rog-control-center.cfg" ] || [ -L "$HOME/.config/rog/rog-control-center.cfg" ]; then
      mkdir -p "$HOME/.config/rog"
      cp -f "${../shared/rog/rog-control-center.cfg}" "$HOME/.config/rog/rog-control-center.cfg"
      chmod 644 "$HOME/.config/rog/rog-control-center.cfg"
    fi
  '';
}
