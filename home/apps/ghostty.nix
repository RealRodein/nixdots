{ hostName, ... }:

let
  theme = if hostName == "orbiter" then "noctalia" else "matugen";
in
{
  xdg.configFile."ghostty/config".text = ''
    theme = ${theme}
    window-decoration = client
    window-theme = ghostty
  '';

  xdg.configFile."ghostty/titlebar-sync.sh".source = ../shared/ghostty/titlebar-sync.sh;
}
