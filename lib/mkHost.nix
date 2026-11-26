{ nixpkgs, home-manager, lsfg-vk, inputs }:

let
  user = import ./user.nix;
in

{ system, hostName, hostPath }:
nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = { inherit inputs hostName user; };

  modules = [
    hostPath

    home-manager.nixosModules.home-manager
    lsfg-vk.nixosModules.default

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = {
          inherit inputs hostName user;
        };

        # Each host owns its Home Manager entrypoint, so host-specific imports
        # stay visible in home/hosts/<host>.nix instead of being derived from
        # the machine name in a shared conditional import list.
        users.${user.name} = import (../home/hosts + "/${hostName}.nix");
      };
    }
  ];
}
