{ pkgs, ... }:
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
    # Niri session
    xwayland
    xwayland-satellite

    # File manager
    nautilus

    # Windows compatibility
    wineWow64Packages.waylandFull
    winetricks

    # ASUS
    asusctl
    supergfxctl

    # Power
    auto-cpufreq
  ];
}
