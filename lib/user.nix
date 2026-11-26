rec {
  # Single source of truth for the desktop account. Both NixOS modules and
  # Home Manager modules receive this file through specialArgs, so changing the
  # account here is enough to update every host.
  name = "rodein";
  gitName = "RealRodein";
  email = "rodein.personal@gmail.com";
  home = "/home/${name}";
}
