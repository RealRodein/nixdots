{ ... }:

{
  users.users.rodein = {
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "libvirtd" ];
  };
}
