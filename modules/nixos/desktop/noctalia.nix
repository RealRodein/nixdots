{ pkgs, inputs, ... }:

{
  # Live-edit workflow:
  # - Noctalia state is edited in home/orbiter/dotfiles/noctalia/
  # - Rebuild with: sudo nixos-rebuild switch --flake ~/NixDOTs#orbiter

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
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
