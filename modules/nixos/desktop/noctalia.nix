{ pkgs, inputs, ... }:

let
  # Umbriel and its portal backend are only packaged in nixpkgs-unstable.
  # Keep the rest of the system on nixos-26.05 and pull just these bits in.
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # niri 26.04's niri-session calls `systemctl --user import-environment` with
  # no variable list. systemd 260 deprecates that form and prints
  # "Calling import-environment without a list of variable names is
  # deprecated." Patch the packaged script (without rebuilding niri) so the
  # fallback Niri session still works.
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
  imports = [
    # Module comes from unstable too, so its defaults line up with the package.
    (import "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/umbriel.nix")
  ];

  programs.umbriel = {
    enable = true;
    package = unstablePkgs.umbriel;
    portalPackage = unstablePkgs.xdg-desktop-portal-umbriel;
  };

  # Live-edit workflow:
  # - Noctalia state is edited in home/orbiter/dotfiles/noctalia/
  # - Umbriel config is generated from home/desktop/umbriel.nix
  # - Rebuild with: sudo nixos-rebuild switch --flake ~/nixdots#orbiter

  # Autologin into Umbriel. Greetd still registers both compositors as
  # sessions, so Niri remains available if you switch session/launch it from a
  # TTY (see README for switching back).
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${unstablePkgs.umbriel}/bin/start-umbriel";
      user = "rodein";
    };
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

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
    unstablePkgs.noctalia
  ];
}
