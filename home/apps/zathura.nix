{ config, lib, machineName, ... }:

let
  ayuColors = ''
    set default-bg "#0b0e14"
    set default-fg "#d1d1c7"
    set statusbar-bg "#1e222a"
    set statusbar-fg "#d1d1c7"
    set inputbar-bg "#1e222a"
    set inputbar-fg "#d1d1c7"
    set notification-bg "#1e222a"
    set notification-fg "#d1d1c7"
    set notification-error-bg "#d95757"
    set notification-error-fg "#0b0e14"
    set notification-warning-bg "#e6b450"
    set notification-warning-fg "#0b0e14"
    set highlight-color "#e6b450"
    set highlight-active-color "#39bae6"
    set completion-bg "#1e222a"
    set completion-fg "#d1d1c7"
    set completion-highlight-bg "#39bae6"
    set completion-highlight-fg "#0b0e14"
    set recolor-lightcolor "#0b0e14"
    set recolor-darkcolor "#d1d1c7"
  '';
in
{
  xdg.configFile."zathura/zathurarc".text = ''
    include ${config.home.homeDirectory}/.config/zathura/matugen

    set selection-clipboard clipboard
    set incremental-search true
    set adjust-open width
    set scroll-step 100
    set zoom-step 10
    set smooth-scroll true
    set font "JetBrainsMono Nerd Font Mono 10"
  '';

  xdg.configFile."zathura/matugen" = lib.mkIf (machineName == "orbiter") {
    text = ayuColors;
    force = true;
  };
}
