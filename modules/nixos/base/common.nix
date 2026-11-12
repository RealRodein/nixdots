{ ... }:

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

  # Reboots spent ~90s waiting for the graphical session to stop. systemd's
  # default DefaultTimeoutStopSec is 90s, and niri.service waits in
  # "final-sigterm" for child processes (wineserver/winedevice.exe, Electron)
  # that ignore SIGTERM. Cap the per-user stop timeout so they are SIGKILLed
  # promptly instead of holding up every reboot/shutdown.
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  # The intel_oc_wdt driver does not stop cleanly. systemd's default
  # RebootWatchdogSec=10min makes it open /dev/watchdog0 during shutdown,
  # which logs "watchdog: watchdog0: watchdog did not stop!". The watchdog is
  # not the cause of the slow reboot; disable it to silence the misleading
  # message (the kernel "nowatchdog" param does not affect systemd's use).
  systemd.settings.Manager.RebootWatchdogSec = "0";

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

  services.upower.enable = true;
  services.power-profiles-daemon.enable = false;
  services.flatpak.enable = true;
}
