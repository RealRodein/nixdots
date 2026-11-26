{ pkgs, ... }:

{
  # Railjack's Umbriel settings file: appearance (corner radius, borders, blur),
  # focus/window/workspace keybinds, layout, and window/layer rules. Home Manager
  # renders this to ~/.config/umbriel/config.toml; Umbriel applies most changes
  # live. Noctalia's own settings/state stay user-managed on railjack (unlike
  # orbiter's live-edit checkout).
  xdg.configFile."umbriel/config.toml" = {
    force = true;
    text = ''
      [general]
      autostart = [ "noctalia" ]
      show_cheatsheet = true

      # GPU selection is pinned to the RTX 3070 through WLR_DRM_DEVICES in the
      # Umbriel systemd unit on railjack. Do not use [drm] exclusions here:
      # the NVIDIA EGL allocator also opens /dev/nvidia0 (the 1050 Ti), which
      # Umbriel treats as a forbidden excluded GPU and aborts startup.

      # The monitor advertises 120 Hz but the driver prefers 60 Hz.
      [output.HDMI-A-2]
      mode = "1920x1080@120"

      [input.keyboard]
      layout = "cz"
      variant = "coder"
      options = "ctrl:rctrl_shift"
      numlock_toggle = true

      # Noctalia's Umbriel recommendations, tuned for a dark desktop.
      [appearance]
      prefer_no_csd = false
      border_width = 2
      corner_radius = 3

      [appearance.blur]
      enabled = true
      optimized = true
      passes = 2
      radius = 3
      noise = 0.02
      brightness = 0.9
      contrast = 0.9
      saturation = 1.1

      # Defining [keybinds] replaces the built-in set, so the window/workspace
      # binds are kept alongside the shell and application shortcuts.
      [keybinds]
      # Applications and shell
      "Mod+T" = { action = "spawn ghostty", repeat = false }
      "Mod" = "spawn noctalia msg panel-toggle launcher"
      "Mod+S" = "spawn noctalia msg panel-toggle control-center"
      "Mod+Alt+S" = "spawn noctalia msg settings-toggle"
      "Alt+Tab" = "spawn noctalia msg window-switcher hold"
      #"Alt+Shift+Tab" = "spawn noctalia msg window-switcher hold reverse"
      #"Mod+Shift+A" = "spawn noctalia msg screenshot-annotate"
      #"Mod+Shift+R" = "spawn noctalia msg config-reload"
      "Mod+Q" = { action = "window-close", repeat = false }
      #"Mod+Escape" = "session-quit"
      #"Mod+Shift+Escape" = { action = "shortcuts-inhibit-toggle", allow_when_inhibited = true, repeat = false }

      # Familiar app shortcuts from the old desktop.
      #"Ctrl+Alt+T" = { action = "spawn ghostty", repeat = false }
      "Mod+B" = { action = "spawn firefox", repeat = false }
      "Mod+E" = { action = "spawn luciole", repeat = false }
      "Mod+C" = { action = "spawn zed", repeat = false }
      "Mod+Shift+E" = { action = "spawn ghostty -e yazi", repeat = false }
      "Mod+L" = { action = "spawn noctalia msg session lock", repeat = false }

      # Media/volume/brightness keys go through Noctalia so its OSDs show.
      "XF86AudioRaiseVolume" = { action = "spawn noctalia msg volume-up", allow_when_locked = true }
      "XF86AudioLowerVolume" = { action = "spawn noctalia msg volume-down", allow_when_locked = true }
      "XF86AudioMute" = { action = "spawn noctalia msg volume-mute", allow_when_locked = true, repeat = false }
      "XF86AudioPlay" = { action = "spawn noctalia msg media toggle", allow_when_locked = true, repeat = false }
      "XF86AudioNext" = { action = "spawn noctalia msg media next", allow_when_locked = true }
      "XF86AudioPrev" = { action = "spawn noctalia msg media previous", allow_when_locked = true }
      "XF86MonBrightnessUp" = { action = "spawn noctalia msg brightness-up", allow_when_locked = true }
      "XF86MonBrightnessDown" = { action = "spawn noctalia msg brightness-down", allow_when_locked = true }

      # Focus and movement
      "Mod+Left" = "window-focus-left"
      "Mod+Down" = "window-focus-down"
      "Mod+Up" = "window-focus-up"
      "Mod+Right" = "window-focus-right"
      #"Mod+H" = "window-focus-left"
      #"Mod+J" = "window-focus-down"
      #"Mod+K" = "window-focus-up"
      #"Mod+F1" = "window-focus-next"
      #"Mod+Shift+Left" = "column-move-left"
      #"Mod+Shift+Down" = "window-move-down"
      #"Mod+Shift+Up" = "window-move-up"
      #"Mod+Shift+Right" = "column-move-right"

      # Window state and layout
      # Stacking already floats every window, and Mod+T now opens the terminal.
      #"Mod+T" = { action = "window-toggle-floating", repeat = false }
      "Mod+Shift+T" = { action = "window-focus-switch-floating", repeat = false }
      "Mod+P" = { action = "window-toggle-pinned", repeat = false }
      "Mod+M" = { action = "window-toggle-maximize-to-edges", repeat = false }
      "Mod+F" = { action = "window-toggle-fullscreen", repeat = false }
      "Mod+Ctrl+F" = { action = "window-toggle-maximize", repeat = false }
      "Mod+Minus" = "window-modify-primary-extent -0.02"
      "Mod+Equal" = "window-modify-primary-extent +0.02"
      "Mod+Ctrl+Minus" = "window-modify-secondary-extent -0.02"
      "Mod+Ctrl+Equal" = "window-modify-secondary-extent +0.02"
      "Mod+W" = { action = "column-toggle-tabbed", repeat = false }
      "Mod+Alt+Right" = "column-focus-tab-next"
      "Mod+Alt+Left" = "column-focus-tab-previous"
      "Mod+WheelUp" = "window-focus-left"
      "Mod+WheelDown" = "window-focus-right"
      "Mod+O" = { action = "overview-toggle", repeat = false }

      # Workspaces
      "Mod+1" = "workspace-switch 1"
      "Mod+2" = "workspace-switch 2"
      "Mod+3" = "workspace-switch 3"
      "Mod+4" = "workspace-switch 4"
      "Mod+5" = "workspace-switch 5"
      "Mod+6" = "workspace-switch 6"
      "Mod+7" = "workspace-switch 7"
      "Mod+8" = "workspace-switch 8"
      "Mod+9" = "workspace-switch 9"
      "Mod+Shift+1" = "window-move-to-workspace 1"
      "Mod+Shift+2" = "window-move-to-workspace 2"
      "Mod+Shift+3" = "window-move-to-workspace 3"
      "Mod+Shift+4" = "window-move-to-workspace 4"
      "Mod+Shift+5" = "window-move-to-workspace 5"
      "Mod+Shift+6" = "window-move-to-workspace 6"
      "Mod+Shift+7" = "window-move-to-workspace 7"
      "Mod+Shift+8" = "window-move-to-workspace 8"
      "Mod+Shift+9" = "window-move-to-workspace 9"

      # Scratchpad
      "Mod+Shift+Space" = { action = "window-move-to-scratchpad", repeat = false }
      "Mod+Space" = "scratchpad-toggle"
      "Mod+Ctrl+Space" = { action = "window-restore-from-scratchpad", repeat = false }
      "Mod+Tab" = "scratchpad-focus-next"

      # Railjack is a floating-window desktop. Stacking is the default for new
      # workspaces; none of the keybinds above call workspace-set-layout.
      [layout]
      mode = "stacking"
      extent_presets = [ 0.333, 0.5, 0.667 ]

      # Dragging to an edge or corner snaps to a half or quarter. Umbriel has
      # no drag zone that maximizes the whole window; use Mod+Ctrl+F for that.
      [layout.stacking]
      drop_zones = true

      [layout.scrolling]
      default_extent_fraction = 0.5

      [[window_rule]]
      blur = true

      [[window_rule]]
      match.app_id = "^dev.noctalia.Noctalia$"
      default_floating = true
      default_floating_size_px = { width = 1020, height = 900 }

      [[window_rule]]
      match.app_id = "^dev.noctalia.UmbrielSharePicker$"
      default_floating = true
      default_floating_size_px = { width = 800, height = 600 }

      [[window_rule]]
      match.title = "^(Picture-in-Picture|Picture in picture)$"
      default_floating = true
      default_maximize = false
      default_position = { x = 20, y = 20, anchor = "bottom_right" }

      [[window_rule]]
      match.title = "^notificationtoasts_.+_desktop"
      default_position = { x = 0, y = 0, anchor = "bottom_right" }
      default_focused = false
      default_pinned = true

      # Keep game menus inside their window; a focus/workspace key releases the pointer.
      [[window_rule]]
      match.app_id = "^steam_app_.*$"
      confine_pointer = true

      # Blur Noctalia's layer-shell surfaces, including popups. Panels and OSDs
      # sit over live windows, so they need the non-optimized blur path.
      [[layer_rule]]
      match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$"
      blur = true
      blur_ignore_alpha = 0.5
      blur_popups = true

      [[layer_rule]]
      match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$"
      blur_optimized = false

      [hot_corners.top_left]
      enabled = true
      delay_ms = 500
      action = "overview-open"
    '';
  };
}
