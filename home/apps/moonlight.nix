{ pkgs, ... }:

{
  # Moonlight client for streaming from the Sunshine host on railjack.
  # Orbiter-only, so home/hosts/orbiter.nix imports this module.
  home.packages = [ pkgs.moonlight-qt ];
}
