{ machineName, ... }:

let
  settings = {
    base_keymap = "VSCode";
    ui_font_size = 15;
    buffer_font_size = 14;
    theme = if machineName == "orbiter" then "Ayu Dark" else "Matugen";
    relative_line_numbers = true;
    soft_wrap = "editor_width";
    vim_mode = false;
    autosave = "on_focus_change";
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    languages.Nix.formatter.language_server.name = "nil";
  };
in
{
  xdg.configFile."zed/settings.json" = {
    text = builtins.toJSON settings;
    force = true;
  };
}
