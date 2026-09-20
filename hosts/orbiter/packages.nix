{ pkgs, inputs, ... }:
{
  # xwayland-satellite 0.8.2 breaks Steam (bug in xwayland-satellite),
  # downgrade to 0.8.1 until upstream fixes it.
  nixpkgs.overlays = [
    (final: prev: let
      src081 = final.fetchFromGitHub {
        owner = "Supreeeme";
        repo = "xwayland-satellite";
        tag = "v0.8.1";
        hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
      };
    in {
      xwayland-satellite = prev.xwayland-satellite.overrideAttrs (old: {
        name = "xwayland-satellite-0.8.1";
        version = "0.8.1";
        src = src081;
        cargoDeps = final.rustPlatform.fetchCargoVendor {
          name = "xwayland-satellite-0.8.1";
          inherit src081;
          hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
        };
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    # Desktop
    ghostty
    yazi

    #opencode
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode

    steam
    gamescope
    prismlauncher
    heroic
    mangohud
    xwayland
    xwayland-satellite
    vesktop
    pavucontrol
    mpv
    mpvpaper
    wineWow64Packages.waylandFull
    winetricks

    # File manager
    thunar

    # Editor
    zed-editor

    # CLI tools
    btop
    git
    p7zip
    neovim
    lazygit
    python3

    wtype
    jq
    bubblewrap

    # ASUS
    asusctl
    supergfxctl

    # Power
    auto-cpufreq

    appimage-run
    dotnet-runtime_10
    unzip
    rpm
    # Custom
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
