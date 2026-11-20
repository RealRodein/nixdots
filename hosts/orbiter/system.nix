{ config, ... }:

{
  networking.hostName = "orbiter";

  # File manager integration: removable drives, trash, network mounts.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  networking.firewall.allowedTCPPorts = [ 46561 ];
  networking.firewall.allowedUDPPorts = [ 46561 ];

  # Headset microphone hotplug is handled natively by PipeWire/WirePlumber:
  # the ALC285 exposes an "analog-input-mic" route that becomes available when
  # the combo jack detects a mic, and the existing source node switches to it.
  # No udev rule or userspace script is needed (HDA jack events are not
  # emitted as sound-subsystem udev events anyway).

  # --- GPU ---
  # Shared NVIDIA defaults live in modules/nixos/hardware/nvidia.nix. The
  # laptop-specific bits (open driver, pinned package, PRIME offload) stay here.
  hardware.nvidia = {
    open = true;

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

  system.stateVersion = "26.05";
}
