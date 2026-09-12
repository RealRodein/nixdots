{ pkgs, ... }:

{
  users.users.rodein = {
    isNormalUser = true;
    shell = pkgs.fish;
  };
}
