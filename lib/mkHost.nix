{ nixpkgs, home-manager, lsfg-vk, inputs }:

{ system, hostName, hostPath }:
nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = { inherit inputs hostName; };

  modules = [
    hostPath

    home-manager.nixosModules.home-manager
    lsfg-vk.nixosModules.default

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = {
          inherit inputs hostName;
        };

        # Each host owns its Home Manager entrypoint, so host-specific imports
        # stay visible in home/hosts/<host>.nix instead of being derived from
        # the machine name in a shared conditional import list.
        users.rodein = import (../home/hosts + "/${hostName}.nix");
      };
    }
  ];
}
