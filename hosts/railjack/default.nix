{ ... }:

{
  imports = [
    ../../modules/nixos/base/common.nix
    ../../modules/nixos/packages/common.nix
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
    ../../modules/nixos/users/rodein-base.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/features/gaming.nix
    ../../modules/nixos/features/tailscale.nix

    ./hardware.nix
    ./system.nix
    ./cosmic.nix
    ./users.nix
    ./packages.nix
  ];
}
