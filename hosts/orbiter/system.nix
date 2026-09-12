{ config, lib, pkgs, inputs, ... }:

{
  # --- Boot ---
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
    editor = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "udev.log_level=3"
    "vt.global_cursor_default=0"
    "nowatchdog"
    "intel_pstate=no_turbo"
  ];

  # --- System ---
  networking.hostName = "orbiter";
  networking.firewall.allowedTCPPorts = [ 46561 ];
  networking.firewall.allowedUDPPorts = [ 46561 ];

  services.xserver.xkb = {
    layout = "cz";
    variant = "coder";
    options = "ctrl:rctrl_shift";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;

    # TEMP: 595.71.05 doesn't build on linux 7.2 ("strncpy" removed from the
    # kernel, drm_atomic_state renamed). NVIDIA fixed both in 610.57.04
    # (upstream PR open-gpu-kernel-modules#1227, nixpkgs#554125).
    # Remove once nixos-26.05 ships >= 610.57.04 as default.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "610.57.04";
      sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
      sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
      openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
      settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
      persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
    };

    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Force Full RGB on HDMI to fix washed-out colors
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="RMForceFullRangeRGB=1"
  '';

  # --- Kernel ---
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- ASUS / GPU switching ---
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  services.asusd.enable = true;
  # services.supergfxd.enable = true;

  # Poll no_turbo every 1s — asusd re-enables it otherwise
  systemd.services.disable-turbo = {
    description = "Keep Intel Turbo Boost disabled";
    wantedBy = [ "multi-user.target" ];
    after = [ "sysinit.target" ];
    before = [ "asusd.service" "auto-cpufreq.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "1s";
      ExecStart = "${pkgs.writeShellScript "disable-turbo" ''
        while true; do
          echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
          sleep 1
        done
      ''}";
    };
  };

  systemd.services.auto-cpufreq = {
    description = "auto-cpufreq - Automatic CPU speed & power optimizer";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bash ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.auto-cpufreq}/bin/auto-cpufreq --daemon";
      Restart = "on-failure";
    };
  };

  system.stateVersion = "26.05";
}
