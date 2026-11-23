{ config, pkgs, ... }:

{
  networking.hostName = "railjack";

  # This network has no working IPv6 (router only gives link-local), but DNS
  # still returns AAAA records, so browsers prefer IPv6 and hang on sites like
  # YouTube/Gemini until (or never) falling back to IPv4. Prefer IPv4 in
  # resolution so those sites load immediately, while keeping IPv6 usable on
  # networks that actually provide it.
  networking.getaddrinfo.precedence."::ffff:0:0/96" = 100;

  # --- Locale / Region ---
  # NixOS has no /etc/locale.gen, so locales only exist if declared here.
  # Only en_US.UTF-8 existed before, which left the desktop's "Region &
  # Language" settings page with nothing to offer.
  i18n = {
    defaultLocale = "cs_CZ.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "cs_CZ.UTF-8";
      LC_NUMERIC = "cs_CZ.UTF-8";
      LC_MONETARY = "cs_CZ.UTF-8";
      LC_PAPER = "cs_CZ.UTF-8";
      LC_MEASUREMENT = "cs_CZ.UTF-8";
      LC_TELEPHONE = "cs_CZ.UTF-8";
    };
  };

  # --- Display / Desktop ---
  # The XFCE X11 session, greetd autologin and portals live in ./xfce.nix.
  # The NVIDIA/Xorg wiring shared by both hosts is in modules/nixos/hardware/.

  services.orca.enable = false;           # screen reader
  services.fwupd.enable = false;          # firmware update daemon

  # --- Swap ---
  # This box has 15 GiB of RAM, 12 cores and no swap, so Nix defaults to 12
  # parallel build jobs and any large compile (the nvidia driver)
  # drives the box into a global OOM. The kernel then picks victims at random -
  # it took out nix mid-rebuild, vesktop, ghostty, pipewire and dbus-broker -
  # which is what the desktop surfaces as "the system is killing apps to protect
  # the kernel". 8 GiB is enough to let a build oversubscribe instead of dying.
  systemd.tmpfiles.rules = [ "d /var/swap 0777 root root - " ];
  swapDevices = [
    {
      device = "/var/swap/swapfile";
      size = 8192; # MiB
      priority = 10;
    }
  ];

  services.system76-scheduler.enable = true;

  # --- Game streaming ---
  # Sunshine is the host; Moonlight on orbiter connects to it. Settings and
  # application entries are left to Sunshine's web UI so they stay editable.
  services.sunshine = {
    enable = true;
    openFirewall = true;
    # Required for DRM/KMS screen capture; installs a capability wrapper.
    capSysAdmin = true;
  };

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  hardware.i2c.enable = true;
  boot.kernelModules = [ "i2c-dev" ];

  # Shared NVIDIA defaults live in modules/nixos/hardware/nvidia.nix. This
  # desktop keeps the proprietary driver and its pinned package.
  # nixpkgs-26.05's nvidia 595.71.05 fails to compile against linux 7.2
  # (implicit 'strncpy' declaration removed), so pin the fixed 595.99.02 driver.
  hardware.nvidia = {
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.99.02";
      sha256_64bit = "sha256-6HR3lYv3YwcFSTJL1a1slI66btIQ5EAFs+/4SUD24ew=";
      sha256_aarch64 = "sha256-CCqHZTN2KNOZ4yZp2rDcuRJp9pHfRw47k4m4dWnS/2w=";
      openSha256 = "sha256-T36x/jx8yQ8l3LFp1rZIrTfcSwbGy8YSAvXOUSptpb4=";
      settingsSha256 = "sha256-GYCcnxfKPrTCrsmd25sMyzfC5cqJQJx0c31haooyTYM=";
      persistencedSha256 = "sha256-VyKtF/HdHPQrHHK6opSO69M72LmnGZtauuchj9uuje8=";
    };
  };

  # --- Frame generation ---
  # lsfg-vk: Lossless Scaling's frame generation as a Vulkan implicit layer,
  # active per-app with ENABLE_LSFG=1 (or a profile in ~/.config/lsfg-vk/conf.toml).
  # Requires Lossless Scaling (paid) installed in Steam for the model DLL.
  services.lsfg-vk = {
    enable = true;
    ui.enable = true;
  };

  # --- Kernel ---
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  system.stateVersion = "26.05";
}
