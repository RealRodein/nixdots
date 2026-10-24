{ machineName, lib, ... }:

{
  imports =
    [
      ./common
      ./apps/ghostty.nix
      ./apps/yazi.nix
      ./apps/zed.nix
      ./apps/btop.nix
      ./apps/mpv.nix
      ./apps/zathura.nix
      ./apps/imv.nix
      ./apps/firefox.nix
      ./apps/chromium.nix
    ]
    ++ lib.optionals (machineName == "orbiter") [
      ./apps/nautilus.nix
      ./desktop/niri.nix
      ./desktop/noctalia.nix
      ./hosts/orbiter.nix
    ]
    ++ lib.optionals (machineName == "railjack") [
      ./desktop/cosmic.nix
      ./desktop/matugen.nix
      ./hosts/railjack.nix
    ];
}
