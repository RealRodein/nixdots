{ ... }:

{
  imports = [
    ../../modules/nixos/base/common.nix
    ../../modules/nixos/packages/common.nix
    ../../modules/nixos/users/rodein-base.nix

    ./hardware.nix
    ./system.nix
    ./vfio.nix
    ./users.nix
    ./packages.nix
  ];
}
