{ ... }:

{
  imports = [
    # Shared modules for all hosts.
    ../../modules/nixos/base/common.nix
    ../../modules/nixos/packages/common.nix
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
    ../../modules/nixos/users/rodein-base.nix

    # Orbiter live desktop module (Noctalia/Niri).
    ../../modules/nixos/desktop/noctalia.nix

    # Shared feature modules.
    ../../modules/nixos/features/gaming.nix

    # Host-local modules (keep hardware local to host).
    ./hardware.nix
    ./system.nix
    ./users.nix
    ./packages.nix
    ./fonts.nix
  ];
}
