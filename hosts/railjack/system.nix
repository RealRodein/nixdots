{ config, lib, pkgs, user, ... }:

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
  # The Umbriel + Noctalia session, greetd autologin and portals live in
  # ./umbriel.nix. Shared NVIDIA defaults are in modules/nixos/hardware/.

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

  # --- Recovery SSH ---
  # SSH exists only so orbiter can recover this host if the graphical session
  # breaks. The firewall rules below are inserted ahead of the trusted
  # tailscale0 rule, so no other Tailscale peer or LAN device can reach sshd.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ user.name ];
    };
  };

  networking.firewall.extraCommands = ''
    # orbiter: Tailscale address and current LAN address.
    iptables -I nixos-fw 1 -p tcp -s 100.69.25.98 --dport 22 -j nixos-fw-accept
    iptables -I nixos-fw 2 -p tcp -s 192.168.50.106 --dport 22 -j nixos-fw-accept
    iptables -I nixos-fw 3 -p tcp -i lo --dport 22 -j nixos-fw-accept
    iptables -I nixos-fw 4 -p tcp --dport 22 -j nixos-fw-refuse
    ${lib.optionalString config.networking.enableIPv6 ''
      ip6tables -I nixos-fw 1 -p tcp -i lo --dport 22 -j nixos-fw-accept
      ip6tables -I nixos-fw 2 -p tcp --dport 22 -j nixos-fw-refuse
    ''}
  '';

  # --- Game streaming ---
  # Sunshine is the host; Moonlight on orbiter connects to it. Settings and
  # application entries are left to Sunshine's web UI so they stay editable.
  services.sunshine = {
    enable = true;
    openFirewall = true;
    # Required for DRM/KMS screen capture; installs a capability wrapper.
    capSysAdmin = true;
    # The default nixpkgs build sets SUNSHINE_ENABLE_CUDA=false. ffmpeg can
    # still find h264_nvenc, but Sunshine's CUDA upload path is compiled out,
    # so portal frames fail in the software converter and Moonlight receives no
    # video.
    package = (pkgs.sunshine.override { cudaSupport = true; }).overrideAttrs (old: {
      # Sunshine sees an all-NVIDIA system and tries to import PipeWire DMA-BUFs
      # from the 3070 directly into CUDA on the 1050 Ti. That fails with
      # EGL_BAD_MATCH (0x3009). Force its system-memory CUDA path instead:
      # portal frames are copied to RAM, then uploaded to the 1050 Ti for NVENC.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/platform/linux/pipewire.cpp \
          --replace-fail 'BOOST_LOG(info) << "[pipewire] Pure NVIDIA system - DMA-BUF will be enabled for CUDA"sv;' \
                         'BOOST_LOG(info) << "[pipewire] NVIDIA display with split NVENC GPU - CUDA will use memory buffers"sv;' \
          --replace-fail 'display_is_nvidia = true;' \
                         'display_is_nvidia = false; /* railjack: encode GPU differs from display GPU */'
      '';
    });
  };

  # With cudaSupport enabled the package uses autoAddDriverRunpath, but keep an
  # explicit driver path inside the capability wrapper as a fallback after its
  # environment has been sanitised.
  #
  # Railjack splits the GPUs: the RTX 3070 (0000:07:00.0) drives the display
  # and games, while the GTX 1050 Ti (0000:04:00.0) does NVENC. With
  # PCI_BUS_ID ordering the 1050 Ti is CUDA device 0, so hide the 3070 from
  # CUDA and let Sunshine's ffmpeg pick the 1050 Ti for encoding. Capture goes
  # through xdg-desktop-portal-umbriel (`capture = portal` in sunshine.conf):
  # PipeWire frames are copied through system memory and uploaded to CUDA on
  # the 1050 Ti, where NVENC runs. Do NOT set Sunshine's `adapter_name` to the
  # 1050 Ti: that option also selects the capture render node and would break
  # screen capture. Do not use
  # `capture = wlr` either: Umbriel does not advertise wlr-export-dmabuf.
  security.wrappers.sunshine.source = lib.mkForce (pkgs.writeShellScript "sunshine-nvenc" ''
    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export CUDA_DEVICE_ORDER=PCI_BUS_ID
    export CUDA_VISIBLE_DEVICES=0
    exec ${lib.getExe config.services.sunshine.package} "$@"
  '');

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  hardware.i2c.enable = true;
  boot.kernelModules = [ "i2c-dev" ];

  # Shared NVIDIA defaults live in modules/nixos/hardware/nvidia.nix. This
  # host keeps the proprietary driver. 595+ drops Pascal support, so the GTX
  # 1050 Ti is ignored ("supported through the 580.xx Legacy drivers") and
  # only the RTX 3070 shows up in nvidia-smi. The 580 legacy branch still
  # supports both GPUs, so pin it here. A rebuild alone does not unload the old
  # driver: reboot before expecting NVENC to work.
  hardware.nvidia = {
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
