{ pkgs, inputs, user, ... }:

let
  # Keep Noctalia from nixpkgs-unstable; the rest of the system stays on
  # nixos-26.05. Luciole comes from its upstream flake.
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  luciolePkg = inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # systemd 260 warns for every variable passed to import-environment that is
  # not set in the login environment. Filter the list first so boot logs stay
  # quiet while still importing the variables that do exist.
  importNiriEnvironment = pkgs.writeShellScriptBin "import-niri-environment" ''
    for name in XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_DATA_DIRS WAYLAND_DISPLAY DISPLAY; do
      if printenv "$name" >/dev/null 2>&1; then
        set -- "$@" "$name"
      fi
    done
    if [ "$#" -gt 0 ]; then
      systemctl --user import-environment "$@"
    fi
  '';

  # niri 26.04's niri-session calls `systemctl --user import-environment`
  # with no variable list. systemd 260 deprecates that form. Replace that one
  # line with the filtering helper; the rest of the packaged script is intact.
  niriSession = pkgs.runCommandLocal "niri-session-patched" { } ''
    mkdir -p $out/bin
    cp ${pkgs.niri}/bin/niri-session $out/bin/niri-session
    chmod u+w $out/bin/niri-session
    substituteInPlace $out/bin/niri-session \
      --replace-fail 'systemctl --user import-environment' '${importNiriEnvironment}/bin/import-niri-environment'
  '';
in
{
  imports = [
    inputs.luciole.nixosModules.default
  ];

  programs.luciole = {
    enable = true;
    package = luciolePkg;
  };

  # Live-edit workflow:
  # - Noctalia state is edited in home/orbiter/dotfiles/noctalia/
  # - Niri config lives in home/shared/niri/ and is linked by home/desktop/niri.nix
  # - Rebuild with: sudo nixos-rebuild switch --flake ~/nixdots#orbiter

  # Autologin into Niri. Greetd still registers Niri as a Wayland session.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${niriSession}/bin/niri-session";
      user = user.name;
    };
  };

  # Session registration and the user units niri.service / niri-shutdown.target
  # that niri-session starts through systemd.
  services.displayManager.sessionPackages = [ pkgs.niri ];
  systemd.packages = [ pkgs.niri ];

  # winedevice.exe inherits niri.service's cgroup and ignores SIGTERM. With
  # KillMode=control-group systemd waits for every child before SIGKILL, which
  # added ~10s to every reboot. Kill leftover children as soon as niri exits.
  #
  # Use a raw drop-in here instead of systemd.user.services.niri: the service
  # module also emits the NixOS build-time Environment= lines, including a
  # minimal PATH, which hides noctalia/xwayland-satellite from Niri.
  systemd.user.units."niri.service" = {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      KillMode=mixed
      TimeoutStopSec=2s
    '';
  };

  xdg.portal = {
    enable = true;

    # GNOME is required by Niri for screencasting; GTK is the generic fallback.
    # Luciole ships a FileChooser portal backend, so include its package here as
    # well (this also puts its D-Bus service files on the activation path).
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ] ++ [ luciolePkg ];

    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      # Luciole's native dialogs, with GTK as fallback.
      "org.freedesktop.impl.portal.FileChooser" = [ "luciole" "gtk" ];
    };
  };

  environment.systemPackages = [
    unstablePkgs.noctalia
    # Needed by focus-or-spawn.sh / close-or-tab.sh: `niri msg` must be
    # callable from scripts spawned by Niri itself.
    pkgs.niri
  ];
}
