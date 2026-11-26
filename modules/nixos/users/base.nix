{ pkgs, user, ... }:

{
  users.users.${user.name} = {
    isNormalUser = true;
    shell = pkgs.fish;
  };
}
