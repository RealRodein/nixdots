{ user, ... }:

{
  users.users.${user.name} = {
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "tailscale" ];
  };
}
