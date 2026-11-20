{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=WaylandWindowDecorations"
      # GNOME Keyring is not installed; use Chromium's built-in store.
      "--password-store=basic"
    ];
  };
}
