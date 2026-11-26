{ ... }:

let
  theme = "noctalia";
in
{
  xdg.configFile."btop/btop.conf".text = ''
    theme = ${theme}
  '';
}
