{ pkgs, inputs, ... }:

let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  environment.systemPackages = with pkgs; [
    btop
    yazi
    nano
    less
    lazygit
    git

    ripgrep
    fd
    fzf
    zoxide
    bat
    eza
    delta
    ouch
    unar
    p7zip
    file
    poppler-utils
    chafa
    xdg-utils
    jq
    yq-go
    nil
    ncdu
    duf

    wtype
    wl-clipboard
    cliphist
    python3
    bubblewrap

    appimage-run
    dotnet-runtime_10
    unzip
    rpm

    unstable.opencode
  ];
}
