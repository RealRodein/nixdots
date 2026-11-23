{ config, lib, pkgs, ... }:

let
  # XFCE's generated Xsession script starts xfce4-session and exports the
  # variables user units need. greetd does not consume NixOS session files, so
  # start X and that wrapper directly instead of relying on a display greeter.
  xfceSession = lib.head (
    lib.filter (p: lib.elem "xfce" (p.providedSessions or [ ]))
      config.services.displayManager.sessionPackages
  );

  startXfce = pkgs.writeShellScript "start-xfce" ''
    export XDG_CURRENT_DESKTOP=XFCE
    export XDG_SESSION_DESKTOP=xfce
    export XDG_SESSION_TYPE=x11

    exec ${pkgs.xinit}/bin/xinit \
      ${config.services.displayManager.sessionData.wrapper} \
      ${xfceSession} \
      -- -keeptty
  '';
in
{
  services.xserver.enable = true;

  services.xserver.desktopManager.xfce = {
    enable = true;
    enableScreensaver = false;
  };

  # Use the GUI programs already configured on this host instead of XFCE's
  # bundled picks. XFCE's task manager, panel, desktop and Xfwm stay.
  environment.xfce.excludePackages = with pkgs; [
    xfce4-terminal # ghostty is already the default terminal
    mousepad # zed-editor is already installed
    parole # mpv is already the default audio/video player
    ristretto # imv is already the default image viewer
    pavucontrol # already installed by modules/nixos/packages/gui.nix
  ];

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${startXfce}";
      user = "rodein";
    };
  };

  # No location service on this host.
  services.geoclue2.enable = lib.mkForce false;

  # Home Manager must activate with the graphical session, not from a boot-time
  # system unit. Otherwise files that apps rewrite in the meantime (GTK's
  # .gtkrc-2.0, fontconfig's 10-hm-fonts.conf, mimeapps.list) trip Home
  # Manager's collision check and the generation is silently left unapplied.
  home-manager.startAsUserService = true;
}
