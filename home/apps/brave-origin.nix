{ pkgs, ... }:

{
  # Brave Origin is installed on both hosts. Home Manager exposes each supported
  # browser as its own option namespace; the package is overridden from
  # `pkgs.brave` to `pkgs.brave-origin`.
  programs.brave = {
    enable = true;
    package = pkgs.brave-origin;

    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=WaylandWindowDecorations"
    ];
  };
}
