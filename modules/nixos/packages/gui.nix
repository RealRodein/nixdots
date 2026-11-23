{ pkgs, inputs, ... }:

let
  # 26.05 ships Vesktop 1.6.5; 1.6.9 in unstable has considerably improved
  # Rich Presence game detection and full Discord RPC support. Keep the rest
  # of the system on the pinned release.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  environment.systemPackages = with pkgs; [
    ghostty
    zed-editor
    mpv
    mpvpaper
    zathura
    imv
    resources
    pavucontrol
    unstable.vesktop
    file-roller
  ];
}
