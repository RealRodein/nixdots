{ config, inputs, pkgs, ... }:

let
  # Upstream wine-sni-bridge hardcodes the tray title to "Wine App" and prefers
  # the window's _NET_WM_ICON. For Wine apps that property holds Wine's generic
  # wine-glass icon, while the real app icon is what Wine painted into the tray
  # window. Use the miner's name and force the CopyArea path instead.
  wineSniBridge = pkgs.runCommandLocal "wine-sni-bridge-tdm" { } ''
    mkdir -p $out
    cp ${inputs.wine-sni-bridge}/wine-sni-bridge.py $out/wine-sni-bridge.py
    chmod u+w $out/wine-sni-bridge.py
    substituteInPlace $out/wine-sni-bridge.py \
      --replace-fail '"Wine App"' '"Twitch Drops Miner"' \
      --replace-fail 'if icon_prop and icon_prop.value is not None and len(icon_prop.value) >= 3:' \
                     'if False and icon_prop and icon_prop.value is not None and len(icon_prop.value) >= 3:'
  '';

  # The checkout is edited live for Noctalia settings. Keep the path in one
  # place so moving the repository is a single-line change.
  repoDir = "${config.home.homeDirectory}/nixdots";
  noctaliaDots = "${repoDir}/home/orbiter/dotfiles/noctalia";
in
{
  imports = [ "${inputs.wine-sni-bridge}/nix/module.nix" ];

  # Noctalia's tray only speaks StatusNotifierItem (SNI). Wine tray icons use
  # the legacy X11 XEmbed protocol, so bridge them over XWayland into SNI.
  # wine-sni-bridge uses a managed X11 window (unlike xembedsniproxy), which
  # niri can hide with a window rule instead of showing a black square.
  services.wine-sni-bridge = {
    enable = true;
    script = "${wineSniBridge}/wine-sni-bridge.py";
  };

  # Noctalia rewrites settings.toml from its GUI, so this one file must stay a
  # writable symlink into the checkout instead of a read-only store link.
  home.activation.ensureNoctaliaSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/state/noctalia"
    src="${noctaliaDots}/settings.toml"
    dst="$HOME/.local/state/noctalia/settings.toml"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" != "$src" ]; then
      rm -f "$dst"
    fi
    if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
      ln -s "$src" "$dst"
    fi
  '';

  # Logos are read-only assets, so Home Manager can own this link.
  home.file.".local/state/noctalia/logos" = {
    source = ../orbiter/dotfiles/noctalia/logos;
    force = true;
  };
}
