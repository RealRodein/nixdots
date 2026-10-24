{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # COSMIC start menu applet (built by the overlay in cosmic.nix)
    cosmic-start-menu-applet

    # RGB
    openrgb

    # Disk tooling (sgdisk/parted/partprobe)
    gptfdisk
    parted
  ];
}
