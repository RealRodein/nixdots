{ pkgs, ... }:

{
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Prague";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
    cores = 0;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-old-generations 5";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;

  programs.dconf.enable = true;
  programs.fish.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = true;
    package = pkgs.steam.override { extraArgs = "-cef-disable-gpu-compositing"; };
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;
  services.openssh.enable = true;
  services.flatpak.enable = true;
}
