{ pkgs, ... }:

{
  # Intel turbo stays off on this laptop. Keep the kernel parameter and the
  # polling service together; asusd otherwise re-enables turbo.
  boot.kernelParams = [ "intel_pstate=no_turbo" ];

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
}
