{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Desktop
    ghostty
    yazi
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode
    steam
    gamescope
    mangohud
    xwayland
    xwayland-satellite
    vesktop
    pavucontrol
    openrgb
    mpv
    mpvpaper

    # File manager
    nemo

    # Editor
    zed-editor

    # CLI tools
    btop
    git
    p7zip
    neovim
    lazygit

    wtype
    jq

    appimage-run
    dotnet-runtime_10
    unzip
    rpm

    # VM / VFIO
    looking-glass-client
    swtpm
    virt-viewer

    # Custom
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
