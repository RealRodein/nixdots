{ pkgs, inputs, ... }:

{
  programs.dms-shell = {
    enable = true;

    # Startup via niri autostart (see home/shared/niri/config.d/autostart.kdl)
    # instead of systemd; dms run is the non-systemd startup command.
    systemd.enable = false;

    # dms-shell 1.6.3 from nixpkgs-unstable (stable 26.05 has only 1.4.6)
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dms-shell;

    # Core features (module defaults are true; declared explicitly per request)
    enableSystemMonitoring = true;   # dgop
    enableVPN = true;                # glib + networkmanager
    enableDynamicTheming = true;     # matugen
    enableAudioWavelength = true;    # cava
    enableCalendarEvents = true;     # khal
  };

  programs.dsearch.enable = true;

  environment.systemPackages = [
    pkgs.adw-gtk3
    pkgs.qt6.qtimageformats
  ];
}