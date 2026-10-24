{
  description = "NixDOTs system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Lossless Scaling frame generation (Vulkan layer) – needs Lossless Scaling bought on Steam
    lsfg-vk = {
      url = "github:pabloaul/lsfg-vk-flake/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Classic Start menu for the COSMIC panel
    cosmic-start-menu-applet = {
      url = "github:jjnuthuagen/cosmic-start-menu-applet";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, lsfg-vk, ... }:
  let
    system = "x86_64-linux";
    mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager lsfg-vk inputs; };
  in {
    nixosConfigurations.orbiter = mkHost { inherit system; hostPath = ./hosts/orbiter; };
    nixosConfigurations.railjack = mkHost { inherit system; hostPath = ./hosts/railjack; };
  };
}
