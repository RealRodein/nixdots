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

    # Shared hardware and feature modules.
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/features/gaming.nix
    ../../modules/nixos/features/tailscale.nix

    # Host-local modules (keep hardware and machine quirks local to the host).
    ./hardware.nix
    ./system.nix
    ./asus.nix
    ./power.nix
    ./users.nix
    ./packages.nix
    ./fonts.nix
  ];
}
