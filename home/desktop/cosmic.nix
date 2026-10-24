{
  xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
    force = true;
    text = ''
      {
(modifiers: [Super]): Spawn("/run/current-system/sw/bin/cosmic-start-menu-applet --toggle"),
(modifiers: [Super, Shift], key: "e"): Spawn("ghostty -e yazi"),
(modifiers: [Super, Shift], key: "b"): Spawn("chromium"),
}
    '';
  };

  home.file.".local/share/icons/hicolor/scalable/apps/com.system76.CosmicPanelLauncherButton.svg".source =
    ../orbiter/dotfiles/noctalia/logos/nix-snowflake-white.svg;
  home.file.".local/share/icons/hicolor/scalable/apps/com.system76.CosmicLauncher.svg".source =
    ../orbiter/dotfiles/noctalia/logos/nix-snowflake-white.svg;
}
