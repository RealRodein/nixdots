{ machineName, ... }:

let
  theme = if machineName == "orbiter" then "noctalia" else "matugen";
in
{
  xdg.configFile."btop/btop.conf".text = ''
    theme = ${theme}
  '';
}
