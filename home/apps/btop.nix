{ hostName, ... }:

let
  theme = if hostName == "orbiter" then "noctalia" else "matugen";
in
{
  xdg.configFile."btop/btop.conf".text = ''
    theme = ${theme}
  '';
}
