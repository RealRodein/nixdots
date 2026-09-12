{ ... }:

{
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "pnpm-10.29.2" ];

  nixpkgs.overlays = [
    (final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        version = "1.17.18";
        src = final.fetchFromGitHub {
          owner = "anomalyco";
          repo = "opencode";
          tag = "v1.17.18";
          hash = "sha256-Y0rcO6r9yqhYux8IS5oAtgzcMXfJE8I1Lre4HdJ5nBg=";
        };
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = "sha256-kXdXw264JQdlNoZPv5GUyWZvb/A8h2CTRdiX79jyvys=";
        });
      });
    })
  ];
}
