{ ... }:

{
  # NVIDIA defaults shared by both machines. Driver package selection, open vs.
  # proprietary, and PRIME/offload wiring remain host-specific because they
  # depend on the actual GPU configuration.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Runtime PM (and with it the suspend/resume paths) is off by default in
    # this driver config, which leaves the GPU powered across suspend and makes
    # resume fail with a lost video-memory allocation.
    powerManagement.enable = true;

    nvidiaSettings = true;
  };

  # Force Full RGB on HDMI to fix washed-out colors.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="RMForceFullRangeRGB=1"
  '';
}
