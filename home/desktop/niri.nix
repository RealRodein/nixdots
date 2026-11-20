{ ... }:

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
    # Orbiter-only output layout. Managed declaratively instead of being copied
    # by an activation script on every rebuild.
    "niri/config.d/outputs.kdl" = {
      source = ../shared/niri/config.d/outputs-orbiter.kdl;
      force = true;
    };
  };
}
