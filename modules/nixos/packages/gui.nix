{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty
    zed-editor
    mpv
    mpvpaper
    zathura
    imv
    resources
    pavucontrol
    vesktop
    file-roller
  ];
}
