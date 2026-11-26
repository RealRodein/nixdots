{ config, lib, inputs, pkgs, user, ... }:

let
  # The rest of the system stays on nixos-26.05; the compositor, its portal and
  # Noctalia come from the already-locked unstable input.
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  luciolePkg = inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Register the Umbriel session/portal with the nixos-26.05 module system.
  # Its wayland-session helper deliberately leaves XWayland off, hence the
  # explicit programs.xwayland.enable below.
  imports = [
    (import (inputs.nixpkgs-unstable + "/nixos/modules/programs/wayland/umbriel.nix"))
    inputs.luciole.nixosModules.default
  ];

  programs.umbriel = {
    enable = true;
    package = unstablePkgs.umbriel;
    portalPackage = unstablePkgs.xdg-desktop-portal-umbriel;
  };

  # Pin wlroots to the RTX 3070, which owns the connected display. wlroots
  # splits WLR_DRM_DEVICES on ":", so the PCI by-path symlink cannot be used;
  # expose the same card through a colon-free udev symlink instead. This must
  # be a service environment rather than Umbriel's [environment] config table:
  # the latter is applied after backend creation. Do not use [drm] exclusions
  # for the 1050 Ti on the proprietary NVIDIA driver; the EGL allocator opens
  # /dev/nvidia0 too, which makes Umbriel reject its own exclusion policy.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", ENV{ID_PATH}=="pci-0000:07:00.0", SYMLINK+="umbriel-card"
  '';
  systemd.user.services.umbriel.environment.WLR_DRM_DEVICES = "/dev/umbriel-card";

  # Umbriel starts Xwayland lazily for Steam/Proton and other X11 clients; the
  # package wrapper only puts the binary on PATH, it does not install the unit.
  programs.xwayland.enable = true;

  # greetd autologin, mirroring orbiter. start-umbriel enters the login shell,
  # imports the environment into the user manager and starts umbriel.service;
  # unlike SDDM it does not need to own a VT or run Xorg as root.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${unstablePkgs.umbriel}/bin/start-umbriel";
      user = user.name;
    };
  };

  # Noctalia is the shell. Its own config/state is user-managed, so only the
  # package and the autostart entry in home/desktop/umbriel.nix are declarative.
  environment.systemPackages = [ unstablePkgs.noctalia ];

  # Luciole is the file manager on both hosts. Its portal backend provides the
  # FileChooser implementation; xdg-desktop-portal-umbriel already prefers it.
  programs.luciole = {
    enable = true;
    package = luciolePkg;
  };
  xdg.portal.extraPortals = [ luciolePkg ];

  # Removable drives and trash for Luciole.
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # No location service on this host.
  services.geoclue2.enable = lib.mkForce false;

  # Activate Home Manager with the graphical session, not from a boot-time
  # system unit. Files that apps rewrite in the meantime (mimeapps.list,
  # fontconfig, GTK) otherwise trip Home Manager's collision check and leave
  # the generation silently unapplied.
  home-manager.startAsUserService = true;
}
