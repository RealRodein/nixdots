{ ... }:

{
  # Applications shared by every host. Host-only apps (for example Luciole and
  # Moonlight on orbiter) are imported by that host's entrypoint in home/hosts/.
  imports = [
    ./brave-origin.nix
    ./btop.nix
    ./firefox.nix
    ./ghostty.nix
    ./imv.nix
    ./mpv.nix
    ./yazi.nix
    ./zathura.nix
    ./zed.nix
  ];
}
