{ config, ... }:

{
  home.activation.ensureNoctaliaSymlinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    DOTS="$HOME/nixdots/home/orbiter/dotfiles/noctalia"
    mkdir -p "$HOME/.local/state/noctalia"

    link() {
      local src="$1" dst="$2"
      if [ -L "$dst" ] && [ "$(readlink "$dst")" != "$src" ]; then
        rm -f "$dst"
      fi
      if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
        ln -s "$src" "$dst"
      fi
    }

    link "$DOTS/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
    link "$DOTS/logos" "$HOME/.local/state/noctalia/logos"
  '';
}
