{
  description = "NixDOTs system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Luciole is not packaged in nixpkgs yet. Build it from upstream and pin
    # its nixpkgs to our unstable input so the rest stays on nixos-26.05.
    luciole = {
      url = "github:noctalia-dev/luciole";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Lossless Scaling frame generation (Vulkan layer) – needs Lossless Scaling bought on Steam
    lsfg-vk = {
      url = "github:pabloaul/lsfg-vk-flake/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # XEmbed -> StatusNotifierItem bridge for Wine tray icons on Wayland.
    # Needed so Wine apps (Twitch Drops Miner) show up in Noctalia's tray.
    wine-sni-bridge = {
      url = "github:waliori/wine-sni-bridge";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, lsfg-vk, ... }:
  let
    system = "x86_64-linux";
    mkHost = import ./lib/mkHost.nix { inherit nixpkgs home-manager lsfg-vk inputs; };
  in {
    nixosConfigurations.orbiter = mkHost {
      inherit system;
      hostName = "orbiter";
      hostPath = ./hosts/orbiter;
    };

    nixosConfigurations.railjack = mkHost {
      inherit system;
      hostName = "railjack";
      hostPath = ./hosts/railjack;
    };
  };
}
