{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.dms-shell
  ];
}