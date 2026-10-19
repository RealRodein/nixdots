{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Desktop
    ghostty
    yazi
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode
    xwayland
    vesktop
    pavucontrol
    openrgb
    mpv
    mpvpaper

    # COSMIC start menu applet (built by the overlay in cosmic.nix)
    cosmic-start-menu-applet

    # Editor
    zed-editor

    # CLI tools
    btop
    git
    p7zip
    neovim
    lazygit

    # Disk tooling (sgdisk/parted/partprobe)
    gptfdisk
    parted

    wtype
    jq

    appimage-run
    dotnet-runtime_10
    unzip
    rpm

    # Custom
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
