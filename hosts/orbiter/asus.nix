{ config, lib, pkgs, ... }:

{
  # Remap right Ctrl to Shift on the internal keyboard.
  services.keyd = {
    enable = true;
    keyboards.internal = {
      ids = [ "0b05:19b6" ];
      settings = {
        main = {
          rightcontrol = "rightshift";
        };
      };
    };
  };

  # Convert special Fn scroll events (F4/F5/M4) forwarded via keyd's virtual
  # pointer and run their actions. keyd remains enabled for keyboard remapping.
  #
  # The synthetic F18/F20 keys are also written to the virtual output device,
  # but that device is udev-classified as a mouse (ID_INPUT_MOUSE), so libinput
  # consumers such as niri ignore its key events. The actions are therefore run
  # by this service's --hook clauses.
  #
  # Important: do NOT add the `yield` flag to --map. Yielded events skip every
  # subsequent argument (including --hook) and only reach --output.
  systemd.services.asus-fn-scroll-evsieve =
    let
      # Run a command as the desktop user with the Wayland session environment.
      asUser = cmd: pkgs.writeShellScript "evsieve-as-rodein" ''
        uid=$(id -u rodein)
        r="/run/user/$uid"
        exec ${pkgs.util-linux}/bin/runuser -u rodein -- env \
          XDG_RUNTIME_DIR="$r" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$r/bus" \
          WAYLAND_DISPLAY="$(ls "$r"/wayland-* 2>/dev/null | head -n1 | xargs -r basename)" \
          NIRI_SOCKET="$(ls "$r"/niri.*.sock 2>/dev/null | head -n1)" \
          PATH="/run/current-system/sw/bin:/run/wrappers/bin:$PATH" \
          ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg cmd}
      '';
      aura = asUser "asusctl aura effect --next-mode";
      profile = asUser ''
        asusctl profile next
        noctalia msg notification-show "Power Profile" "$(asusctl profile get | sed -n 's/^Active profile: //p')"
      '';
      rog = asUser "bash ${config.users.users.rodein.home}/.config/my-scripts/toggle-rog-cc.sh";
      script = pkgs.writeShellScript "asus-fn-scroll-evsieve" ''
        set -euo pipefail
        dev=""
        for i in $(seq 1 50); do
          for e in /sys/class/input/event*/device/name; do
            if [ "$(cat "$e" 2>/dev/null)" = "keyd virtual pointer" ]; then
              dev="/dev/input/$(basename "$(dirname "$(dirname "$e")")")"
              break 2
            fi
          done
          sleep 0.2
        done
        if [ -z "$dev" ]; then
          echo "keyd virtual pointer not found" >&2
          exit 1
        fi
        exec ${pkgs.evsieve}/bin/evsieve \
          --input "$dev" grab \
          --map rel:hwheel:-1 key:f18:1 key:f18:0 \
          --map rel:hwheel:1  key:f19:1 key:f19:0 \
          --map rel:wheel:1   key:f20:1 key:f20:0 \
          --map rel:wheel:-1  key:f20:1 key:f20:0 \
          --hook key:f18:1 exec-shell="${aura}" \
          --hook key:f19:1 exec-shell="${profile}" \
          --hook key:f20:1 exec-shell="${rog}" \
          --block key:f18 key:f19 key:f20 \
          --output name="asus-fn-remapped"
      '';
    in
    {
      description = "evsieve remap for ASUS Fn scroll events (via keyd virtual pointer)";
      wantedBy = [ "multi-user.target" ];
      after = [ "keyd.service" "systemd-udev-settle.service" ];
      wants = [ "keyd.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${script}";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

  # Prevent the VXE NordicMouse 1K Dongle (3554:f58a) from waking the laptop
  # when the lid is closed and the mouse is bumped. Disable wakeup on the USB
  # device itself, NOT on the parent xHCI controller (0000:00:14.0): the
  # internal keyboard (0b05:19b6) hangs off the same controller, so
  # controller-wide wakeup=disabled breaks keyboard wake as well.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="3554", ATTR{idProduct}=="f58a", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="19b6", ATTR{power/wakeup}="enabled"
  '';

  # ASUS ACPI / GPU switching support.
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  services.asusd.enable = true;
  # services.supergfxd.enable = true;
}
