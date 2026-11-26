{ ... }:

{
  imports = [
    ../../modules/nixos/base/common.nix
    ../../modules/nixos/packages/common.nix
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
    ../../modules/nixos/users/base.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/features/gaming.nix
    ../../modules/nixos/features/tailscale.nix

    ./fonts.nix
    ./hardware.nix
    ./system.nix
    ./umbriel.nix
    ./users.nix
    ./packages.nix
  ];
}
