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
  ];

  # --- System ---
  networking.hostName = "railjack";

  # This network has no working IPv6 (router only gives link-local), but DNS
  # still returns AAAA records, so browsers prefer IPv6 and hang on sites like
  # YouTube/Gemini until (or never) falling back to IPv4. Prefer IPv4 in
  # resolution so those sites load immediately, while keeping IPv6 usable on
  # networks that actually provide it.
  networking.getaddrinfo.precedence."::ffff:0:0/96" = 100;

  # --- Display / Desktop ---
  # Minimal KDE Plasma 6: core shell only, default apps stripped.
  # The plasma6 module already enables SDDM and sets defaultSession = "plasma",
  # as well as the KDE portals (so no manual xdg.portal setup is needed here).
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # Terminal / file manager (we use ghostty + nemo instead)
    konsole
    dolphin
    dolphin-plugins
    baloo-widgets

    # Editor / documents / image / archive / screenshot
    kate
    ktexteditor
    khelpcenter
    okular
    gwenview
    spectacle
    ark

    # Multimedia
    elisa
    ffmpegthumbs

    # Remote desktop
    krdp

    # App store (would be pulled in by Flatpak) & browser integration
    discover
    plasma-browser-integration

    # Look-and-feel extras & touch keyboard (unneeded on desktop)
    aurorae
    plasma-workspace-wallpapers
    plasma-keyboard
    qtvirtualkeyboard
  ];

  # Trim module-enabled extras we don't need on this box.
  programs.kde-pim.enable = false;        # Kontact/KMail/Akonadi PIM stack
  services.orca.enable = false;           # screen reader
  services.geoclue2.enable = false;       # location service
  services.fwupd.enable = false;          # firmware update daemon

  services.system76-scheduler.enable = true;

  services.xserver.xkb = {
    layout = "cz";
    variant = "coder";
    options = "ctrl:rctrl_shift";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Passwordless libvirt control for the vm-usb-toggle hotkey script.
  # Scope limited to virsh so the user can attach/detach USB devices to the
  # Windows VM without a password prompt.
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        { command = "/run/current-system/sw/bin/virsh"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # ── Case power button as "toggle VM input" trigger ──────────────────
  # Short power-press toggles BOTH USB devices (keyboard + mouse) into or out
  # of the VM together; long-press still powers off. This works even when the
  # VM has taken over the keyboard, because the power button is hardware-driven.
  services.logind.settings = {
    Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
    };
  };

  services.acpid = {
    enable = true;
    powerEventCommands = ''
      # acpid runs commands with a minimal PATH, so the script's
      # `#!/usr/bin/env bash` would fail ("bash: No such file or directory").
      # Invoke it through an absolute bash path instead.
      ${pkgs.bash}/bin/bash /etc/vm-usb-toggle-both.sh
      /run/current-system/sw/bin/logger -t vm-power-btn "power button pressed"
    '';
  };

  # Address-independent USB hostdev snippets + the toggle script used by the
  # power-button action (installed under /etc so root/acpid can reach them).
  environment.etc = {
    "vm-usb-keyboard.xml".source = ./vm-usb-keyboard.xml;
    "vm-usb-mouse.xml".source = ./vm-usb-mouse.xml;
    "vm-usb-toggle-both.sh" = {
      source = ../../home/shared/my-scripts/vm-usb-toggle-both.sh;
      mode = "0755";
    };
  };

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  hardware.i2c.enable = true;
  boot.kernelModules = [ "i2c-dev" ];
  # nixpkgs-26.05's nvidia 595.71.05 fails to compile against linux 7.2
  # (implicit 'strncpy' declaration removed), so pin the fixed 595.99.02 driver.
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.99.02";
      sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
      sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
      openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
      settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
      persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
    };
  };

  # Force Full RGB on HDMI to fix washed-out colors
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="RMForceFullRangeRGB=1"
  '';

  # --- Kernel ---
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  system.stateVersion = "26.05";
}
