{
  description = "NixDOTs system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen-browser pinned to 771b9a9c: next version requires ffmpeg_9, only available in nixpkgs-unstable
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager inputs; };
  in {
    nixosConfigurations.orbiter = mkHost { inherit system; hostPath = ./hosts/orbiter; };
    nixosConfigurations.railjack = mkHost { inherit system; hostPath = ./hosts/railjack; };
  };
}
