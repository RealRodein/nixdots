{ config, pkgs, ... }:

let
  # Railjack's Noctalia settings are seeded from this file but stay writable:
  # Noctalia rewrites settings.toml from its GUI, and railjack must never use
  # orbiter's live-edit checkout.
  noctaliaDots = ../railjack/dotfiles/noctalia;

  # Portal restore tokens are single-use, so Sunshine cannot rely on its saved
  # token forever: once it is consumed, the next session opens Umbriel's share
  # picker. Answer every screencast request with the monitor Sunshine streams,
  # with no UI. Only railjack imports this; orbiter's Niri portal is untouched.
  autoChooser = pkgs.writeShellScript "umbriel-auto-chooser" ''
    input=$(cat)
    printf '%s\n' "$input" | ${pkgs.jq}/bin/jq -c '
      if (.outputs | map(select(.name == "HDMI-A-2")) | length) > 0 then
        {selections: [{kind: "monitor", output: "HDMI-A-2"}]}
      elif (.outputs | length) > 0 then
        {selections: [{kind: "monitor", output: .outputs[0].name}]}
      else
        {selections: []}
      end
    '
  '';
in
{
  imports = [
    ../common
    ../apps
    ../apps/luciole.nix
    ../desktop/umbriel.nix
  ];

  gtk.gtk2.force = true;

  xdg.configFile."fontconfig/conf.d/10-hm-fonts.conf".force = true;

  home.activation.seedRailjackNoctalia = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/state/noctalia"
    src="${noctaliaDots}/settings.toml"
    dst="$HOME/.local/state/noctalia/settings.toml"
    if [ -L "$dst" ]; then
      rm -f "$dst"
    fi
    if [ ! -e "$dst" ]; then
      cp -f "$src" "$dst"
      chmod 644 "$dst"
    fi
  '';

  home.file.".local/state/noctalia/logos" = {
    source = "${noctaliaDots}/logos";
    force = true;
  };

  # Skip the interactive share picker for Sunshine's portal screencasts.
  xdg.configFile."xdg-desktop-portal-umbriel/config.toml".text = ''
    [screencast]
    chooser_cmd = "${autoChooser}"
    max_fps = 0
  '';
}
