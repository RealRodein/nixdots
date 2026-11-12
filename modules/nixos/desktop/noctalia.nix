{ pkgs, inputs, ... }:

let
  # niri 26.04's niri-session calls `systemctl --user import-environment` with
  # no variable list. systemd 260 deprecates that form and prints
  # "Calling import-environment without a list of variable names is
  # deprecated." Patch the packaged script (without rebuilding niri) to pass
  # the variables a graphical session actually needs.
  niriSession = pkgs.runCommandLocal "niri-session-patched" { } ''
    mkdir -p $out/bin
    cp ${pkgs.niri}/bin/niri-session $out/bin/niri-session
    chmod u+w $out/bin/niri-session
    substituteInPlace $out/bin/niri-session \
      --replace-fail 'systemctl --user import-environment' \
      'systemctl --user import-environment XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_DATA_DIRS WAYLAND_DISPLAY DISPLAY'
  '';
in
{
  # Live-edit workflow:
  # - Noctalia state is edited in home/orbiter/dotfiles/noctalia/
  # - Rebuild with: sudo nixos-rebuild switch --flake ~/nixdots#orbiter

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${niriSession}/bin/niri-session";
      user = "rodein";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  environment.systemPackages = [
    pkgs.niri
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.noctalia
  ];
}
