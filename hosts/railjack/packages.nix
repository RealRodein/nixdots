{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # RGB
    openrgb

    # Disk tooling (sgdisk/parted/partprobe)
    gptfdisk
    parted
  ];
}
