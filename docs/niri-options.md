# Niri configuration — complete option reference

**Read-only reference.** This file is *not* loaded by niri: `home/desktop/niri.nix` never deploys it and
`config.kdl` does not `include` it. It lives next to your config purely so everything is searchable in one place.

Generated from the official documentation for **niri 26.04** (the version currently provided by your
`nixos-26.05` nixpkgs), shipped locally in the `-niri-26.04-doc` store output. Online originals:
<https://niri-wm.github.io/niri/Configuration%3A-Introduction.html>

## Using this file

- Edit the real config in `home/shared/niri/config.kdl` and `home/shared/niri/config.d/`.
- Check syntax before rebuilding with `niri validate`.
- Config reloads on save; `niri msg action reload-config` forces a reload.
- `KDL` flags are enabled by writing the bare word (`tap`) and disabled by commenting it out (`// tap`).
  `/-` in front of a node comments out that whole node and its children.
- Omitted options keep their defaults, **except `binds {}`**, which is not filled in automatically.
- When niri is upgraded, regenerate this file from the matching `-niri-<version>-doc` store path.

## Section map (every configuration node)

| Config node | Covers | Details in this file |
| --- | --- | --- |
| `input {}` | keyboard, xkb, touchpad, mouse, trackpoint, tablet, touch, Mod key | [Input](#input) |
| `output "NAME" {}` | mode, scale, transform, position, VRR, colors, hot corners | [Outputs](#outputs) |
| `binds {}` | key/mouse binds and every bind action | [Key Bindings](#key-bindings) |
| `switch-events {}` | lid close/open and tablet mode actions | [Switch Events](#switch-events) |
| `layout {}` | gaps, column widths, focus ring, borders, shadows, struts, tab indicator | [Layout](#layout) |
| `workspace "NAME" {}` | named workspaces and per-workspace layout overrides | [Named Workspaces](#named-workspaces) |
| top-level options | autostart, CSD, screenshot path, environment, cursor, overview, Xwayland, clipboard, hotkey overlay, config notification, blur | [Miscellaneous](#miscellaneous) |
| `window-rule {}` | window matching and every dynamic window property | [Window Rules](#window-rules) |
| `layer-rule {}` | layer-shell matching and properties | [Layer Rules](#layer-rules) |
| `animations {}` | easing, springs, custom shaders, all animations | [Animations](#animations) |
| `gestures {}` | edge swipes and hot corners | [Gestures](#gestures) |
| `recent-windows {}` | alt-tab switcher | [Recent Windows](#recent-windows) |
| `debug {}` | diagnostic/experimental switches | [Debug Options](#debug-options) |
| `include "file.kdl"` | splitting and merging config files | [Include](#include) |

## All default options in one place

This is niri's own annotated `default-config.kdl`, verbatim. `//` lines explain the option and show
example values; uncomment what you want to change. It covers the main nodes, while the sections below
add the options that have no home here (rules, key binds, animations, gestures, debug, …).

```kdl
// This config is in the KDL format: https://kdl.dev
// "/-" comments out the following node.
// Check the wiki for a full description of the configuration:
// https://niri-wm.github.io/niri/Configuration:-Introduction

// Input device configuration.
// Find the full list of options on the wiki:
// https://niri-wm.github.io/niri/Configuration:-Input
input {
    keyboard {
        xkb {
            // You can set rules, model, layout, variant and options.
            // For more information, see xkeyboard-config(7).

            // For example:
            // layout "us,ru"
            // options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"

            // If this section is empty, niri will fetch xkb settings
            // from org.freedesktop.locale1. You can control these using
            // localectl set-x11-keymap.
        }

        // Enable numlock on startup, omitting this setting disables it.
        numlock
    }

    // Next sections include libinput settings.
    // Omitting settings disables them, or leaves them at their default values.
    // All commented-out settings here are examples, not defaults.
    touchpad {
        // off
        tap
        // dwt
        // dwtp
        // drag false
        // drag-lock
        natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "two-finger"
        // disabled-on-external-mouse
    }

    mouse {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "no-scroll"
    }

    trackpoint {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // scroll-button-lock
        // middle-emulation
    }

    // Uncomment this to make the mouse warp to the center of newly focused windows.
    // warp-mouse-to-focus

    // Focus windows and outputs automatically when moving the mouse into them.
    // Setting max-scroll-amount="0%" makes it work only on windows already fully on screen.
    // focus-follows-mouse max-scroll-amount="0%"
}

// You can configure outputs by their name, which you can find
// by running `niri msg outputs` while inside a niri instance.
// The built-in laptop monitor is usually called "eDP-1".
// Find more information on the wiki:
// https://niri-wm.github.io/niri/Configuration:-Outputs
// Remember to uncomment the node by removing "/-"!
/-output "eDP-1" {
    // Uncomment this line to disable this output.
    // off

    // Resolution and, optionally, refresh rate of the output.
    // The format is "<width>x<height>" or "<width>x<height>@<refresh rate>".
    // If the refresh rate is omitted, niri will pick the highest refresh rate
    // for the resolution.
    // If the mode is omitted altogether or is invalid, niri will pick one automatically.
    // Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
    mode "1920x1080@120.030"

    // You can use integer or fractional scale, for example use 1.5 for 150% scale.
    scale 2

    // Transform allows to rotate the output counter-clockwise, valid values are:
    // normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
    transform "normal"

    // Position of the output in the global coordinate space.
    // This affects directional monitor actions like "focus-monitor-left", and cursor movement.
    // The cursor can only move between directly adjacent outputs.
    // Output scale and rotation has to be taken into account for positioning:
    // outputs are sized in logical, or scaled, pixels.
    // For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080,
    // so to put another output directly adjacent to it on the right, set its x to 1920.
    // If the position is unset or results in an overlap, the output is instead placed
    // automatically.
    position x=1280 y=0
}

// Settings that influence how windows are positioned and sized.
// Find more information on the wiki:
// https://niri-wm.github.io/niri/Configuration:-Layout
layout {
    // Set gaps around windows in logical pixels.
    gaps 16

    // When to center a column when changing focus, options are:
    // - "never", default behavior, focusing an off-screen column will keep at the left
    //   or right edge of the screen.
    // - "always", the focused column will always be centered.
    // - "on-overflow", focusing a column will center it if it doesn't fit
    //   together with the previously focused column.
    center-focused-column "never"

    // You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
    preset-column-widths {
        // Proportion sets the width as a fraction of the output width, taking gaps into account.
        // For example, you can perfectly fit four windows sized "proportion 0.25" on an output.
        // The default preset widths are 1/3, 1/2 and 2/3 of the output.
        proportion 0.33333
        proportion 0.5
        proportion 0.66667

        // Fixed sets the width in logical pixels exactly.
        // fixed 1920
    }

    // You can also customize the heights that "switch-preset-window-height" (Mod+Ctrl+Shift+R) toggles between.
    // preset-window-heights { }

    // You can change the default width of the new windows.
    default-column-width { proportion 0.5; }
    // If you leave the brackets empty, the windows themselves will decide their initial width.
    // default-column-width {}

    // By default focus ring and border are rendered as a solid background rectangle
    // behind windows. That is, they will show up through semitransparent windows.
    // This is because windows using client-side decorations can have an arbitrary shape.
    //
    // If you don't like that, you should uncomment `prefer-no-csd` below.
    // Niri will draw focus ring and border *around* windows that agree to omit their
    // client-side decorations.
    //
    // Alternatively, you can override it with a window rule called
    // `draw-border-with-background`.

    // You can change how the focus ring looks.
    focus-ring {
        // Uncomment this line to disable the focus ring.
        // off

        // How many logical pixels the ring extends out from the windows.
        width 4

        // Colors can be set in a variety of ways:
        // - CSS named colors: "red"
        // - RGB hex: "#rgb", "#rgba", "#rrggbb", "#rrggbbaa"
        // - CSS-like notation: "rgb(255, 127, 0)", rgba(), hsl() and a few others.

        // Color of the ring on the active monitor.
        active-color "#7fc8ff"

        // Color of the ring on inactive monitors.
        //
        // The focus ring only draws around the active window, so the only place
        // where you can see its inactive-color is on other monitors.
        inactive-color "#505050"

        // You can also use gradients. They take precedence over solid colors.
        // Gradients are rendered the same as CSS linear-gradient(angle, from, to).
        // The angle is the same as in linear-gradient, and is optional,
        // defaulting to 180 (top-to-bottom gradient).
        // You can use any CSS linear-gradient tool on the web to set these up.
        // Changing the color space is also supported, check the wiki for more info.
        //
        // active-gradient from="#80c8ff" to="#c7ff7f" angle=45

        // You can also color the gradient relative to the entire view
        // of the workspace, rather than relative to just the window itself.
        // To do that, set relative-to="workspace-view".
        //
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    // You can also add a border. It's similar to the focus ring, but always visible.
    border {
        // The settings are the same as for the focus ring.
        // If you enable the border, you probably want to disable the focus ring.
        off

        width 4
        active-color "#ffc87f"
        inactive-color "#505050"

        // Color of the border around windows that request your attention.
        urgent-color "#9b0000"

        // Gradients can use a few different interpolation color spaces.
        // For example, this is a pastel rainbow gradient via in="oklch longer hue".
        //
        // active-gradient from="#e5989b" to="#ffb4a2" angle=45 relative-to="workspace-view" in="oklch longer hue"

        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }

    // You can enable drop shadows for windows.
    shadow {
        // Uncomment the next line to enable shadows.
        // on

        // By default, the shadow draws only around its window, and not behind it.
        // Uncomment this setting to make the shadow draw behind its window.
        //
        // Note that niri has no way of knowing about the CSD window corner
        // radius. It has to assume that windows have square corners, leading to
        // shadow artifacts inside the CSD rounded corners. This setting fixes
        // those artifacts.
        //
        // However, instead you may want to set prefer-no-csd and/or
        // geometry-corner-radius. Then, niri will know the corner radius and
        // draw the shadow correctly, without having to draw it behind the
        // window. These will also remove client-side shadows if the window
        // draws any.
        //
        // draw-behind-window true

        // You can change how shadows look. The values below are in logical
        // pixels and match the CSS box-shadow properties.

        // Softness controls the shadow blur radius.
        softness 30

        // Spread expands the shadow.
        spread 5

        // Offset moves the shadow relative to the window.
        offset x=0 y=5

        // You can also change the shadow color and opacity.
        color "#0007"
    }

    // Struts shrink the area occupied by windows, similarly to layer-shell panels.
    // You can think of them as a kind of outer gaps. They are set in logical pixels.
    // Left and right struts will cause the next window to the side to always be visible.
    // Top and bottom struts will simply add outer gaps in addition to the area occupied by
    // layer-shell panels and regular gaps.
    struts {
        // left 64
        // right 64
        // top 64
        // bottom 64
    }
}

// Add lines like this to spawn processes at startup.
// Note that running niri as a session supports xdg-desktop-autostart,
// which may be more convenient to use.
// See the binds section below for more spawn examples.

// This line starts waybar, a commonly used bar for Wayland compositors.
spawn-at-startup "waybar"

// To run a shell command (with variables, pipes, etc.), use spawn-sh-at-startup:
// spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"

hotkey-overlay {
    // Uncomment this line to disable the "Important Hotkeys" pop-up at startup.
    // skip-at-startup
}

// Uncomment this line to ask the clients to omit their client-side decorations if possible.
// If the client will specifically ask for CSD, the request will be honored.
// Additionally, clients will be informed that they are tiled, removing some client-side rounded corners.
// This option will also fix border/focus ring drawing behind some semitransparent windows.
// After enabling or disabling this, you need to restart the apps for this to take effect.
// prefer-no-csd

// You can change the path where screenshots are saved.
// A ~ at the front will be expanded to the home directory.
// The path is formatted with strftime(3) to give you the screenshot date and time.
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

// You can also set this to null to disable saving screenshots to disk.
// screenshot-path null

// Animation settings.
// The wiki explains how to configure individual animations:
// https://niri-wm.github.io/niri/Configuration:-Animations
animations {
    // Uncomment to turn off all animations.
    // off

    // Slow down all animations by this factor. Values below 1 speed them up instead.
    // slowdown 3.0
}

// Window rules let you adjust behavior for individual windows.
// Find more information on the wiki:
// https://niri-wm.github.io/niri/Configuration:-Window-Rules

// Work around WezTerm's initial configure bug
// by setting an empty default-column-width.
window-rule {
    // This regular expression is intentionally made as specific as possible,
    // since this is the default config, and we want no false positives.
    // You can get away with just app-id="wezterm" if you want.
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}

// Open the Firefox picture-in-picture player as floating by default.
window-rule {
    // This app-id regular expression will work for both:
    // - host Firefox (app-id is "firefox")
    // - Flatpak Firefox (app-id is "org.mozilla.firefox")
    match app-id=r#"firefox$"# title="^Picture-in-Picture$"
    open-floating true
}

// Example: block out two password managers from screen capture.
// (This example rule is commented out with a "/-" in front.)
/-window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#

    block-out-from "screen-capture"

    // Use this instead if you want them visible on third-party screenshot tools.
    // block-out-from "screencast"
}

// Example: enable rounded corners for all windows.
// (This example rule is commented out with a "/-" in front.)
/-window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}

binds {
    // Keys consist of modifiers separated by + signs, followed by an XKB key name
    // in the end. To find an XKB name for a particular key, you may use a program
    // like wev.
    //
    // "Mod" is a special modifier equal to Super when running on a TTY, and to Alt
    // when running as a winit window.
    //
    // Most actions that you can bind here can also be invoked programmatically with
    // `niri msg action do-something`.

    // Mod-Shift-/, which is usually the same as Mod-?,
    // shows a list of important hotkeys.
    Mod+Shift+Slash { show-hotkey-overlay; }

    // Suggested binds for running programs: terminal, app launcher, screen locker.
    Mod+T hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }
    Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }
    Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }

    // Use spawn-sh to run a shell command. Do this if you need pipes, multiple commands, etc.
    // Note: the entire command goes as a single argument. It's passed verbatim to `sh -c`.
    // For example, this is a standard bind to toggle the screen reader (orca).
    Super+Alt+S allow-when-locked=true hotkey-overlay-title=null { spawn-sh "pkill orca || exec orca"; }

    // Example volume keys mappings for PipeWire & WirePlumber.
    // The allow-when-locked=true property makes them work even when the session is locked.
    // Using spawn-sh allows to pass multiple arguments together with the command.
    // "-l 1.0" limits the volume to 100%.
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    // Example media keys mapping using playerctl.
    // This will work with any MPRIS-enabled media player.
    XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
    XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
    XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
    XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }

    // Example brightness key mappings for brightnessctl.
    // You can use regular spawn with multiple arguments too (to avoid going through "sh"),
    // but you need to manually put each argument in separate "" quotes.
    XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

    // Open/close the Overview: a zoomed-out view of workspaces and windows.
    // You can also move the mouse into the top-left hot corner,
    // or do a four-finger swipe up on a touchpad.
    Mod+O repeat=false { toggle-overview; }

    Mod+Q repeat=false { close-window; }

    Mod+Left  { focus-column-left; }
    Mod+Down  { focus-window-down; }
    Mod+Up    { focus-window-up; }
    Mod+Right { focus-column-right; }
    Mod+H     { focus-column-left; }
    Mod+J     { focus-window-down; }
    Mod+K     { focus-window-up; }
    Mod+L     { focus-column-right; }

    Mod+Ctrl+Left  { move-column-left; }
    Mod+Ctrl+Down  { move-window-down; }
    Mod+Ctrl+Up    { move-window-up; }
    Mod+Ctrl+Right { move-column-right; }
    Mod+Ctrl+H     { move-column-left; }
    Mod+Ctrl+J     { move-window-down; }
    Mod+Ctrl+K     { move-window-up; }
    Mod+Ctrl+L     { move-column-right; }

    // Alternative commands that move across workspaces when reaching
    // the first or last window in a column.
    // Mod+J     { focus-window-or-workspace-down; }
    // Mod+K     { focus-window-or-workspace-up; }
    // Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
    // Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

    Mod+Home { focus-column-first; }
    Mod+End  { focus-column-last; }
    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End  { move-column-to-last; }

    Mod+Shift+Left  { focus-monitor-left; }
    Mod+Shift+Down  { focus-monitor-down; }
    Mod+Shift+Up    { focus-monitor-up; }
    Mod+Shift+Right { focus-monitor-right; }
    Mod+Shift+H     { focus-monitor-left; }
    Mod+Shift+J     { focus-monitor-down; }
    Mod+Shift+K     { focus-monitor-up; }
    Mod+Shift+L     { focus-monitor-right; }

    Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
    Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

    // Alternatively, there are commands to move just a single window:
    // Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
    // ...

    // And you can also move a whole workspace to another monitor:
    // Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
    // ...

    Mod+Page_Down      { focus-workspace-down; }
    Mod+Page_Up        { focus-workspace-up; }
    Mod+U              { focus-workspace-down; }
    Mod+I              { focus-workspace-up; }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
    Mod+Ctrl+U         { move-column-to-workspace-down; }
    Mod+Ctrl+I         { move-column-to-workspace-up; }

    // Alternatively, there are commands to move just a single window:
    // Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
    // ...

    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+Shift+Page_Up   { move-workspace-up; }
    Mod+Shift+U         { move-workspace-down; }
    Mod+Shift+I         { move-workspace-up; }

    // You can bind mouse wheel scroll ticks using the following syntax.
    // These binds will change direction based on the natural-scroll setting.
    //
    // To avoid scrolling through workspaces really fast, you can use
    // the cooldown-ms property. The bind will be rate-limited to this value.
    // You can set a cooldown on any bind, but it's most useful for the wheel.
    Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

    Mod+WheelScrollRight      { focus-column-right; }
    Mod+WheelScrollLeft       { focus-column-left; }
    Mod+Ctrl+WheelScrollRight { move-column-right; }
    Mod+Ctrl+WheelScrollLeft  { move-column-left; }

    // Usually scrolling up and down with Shift in applications results in
    // horizontal scrolling; these binds replicate that.
    Mod+Shift+WheelScrollDown      { focus-column-right; }
    Mod+Shift+WheelScrollUp        { focus-column-left; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
    Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

    // Similarly, you can bind touchpad scroll "ticks".
    // Touchpad scrolling is continuous, so for these binds it is split into
    // discrete intervals.
    // These binds are also affected by touchpad's natural-scroll, so these
    // example binds are "inverted", since we have natural-scroll enabled for
    // touchpads by default.
    // Mod+TouchpadScrollDown { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+"; }
    // Mod+TouchpadScrollUp   { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-"; }

    // You can refer to workspaces by index. However, keep in mind that
    // niri is a dynamic workspace system, so these commands are kind of
    // "best effort". Trying to refer to a workspace index bigger than
    // the current workspace count will instead refer to the bottommost
    // (empty) workspace.
    //
    // For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
    // will all refer to the 3rd workspace.
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }
    Mod+Ctrl+1 { move-column-to-workspace 1; }
    Mod+Ctrl+2 { move-column-to-workspace 2; }
    Mod+Ctrl+3 { move-column-to-workspace 3; }
    Mod+Ctrl+4 { move-column-to-workspace 4; }
    Mod+Ctrl+5 { move-column-to-workspace 5; }
    Mod+Ctrl+6 { move-column-to-workspace 6; }
    Mod+Ctrl+7 { move-column-to-workspace 7; }
    Mod+Ctrl+8 { move-column-to-workspace 8; }
    Mod+Ctrl+9 { move-column-to-workspace 9; }

    // Alternatively, there are commands to move just a single window:
    // Mod+Ctrl+1 { move-window-to-workspace 1; }

    // Switches focus between the current and the previous workspace.
    // Mod+Tab { focus-workspace-previous; }

    // The following binds move the focused window in and out of a column.
    // If the window is alone, they will consume it into the nearby column to the side.
    // If the window is already in a column, they will expel it out.
    Mod+BracketLeft  { consume-or-expel-window-left; }
    Mod+BracketRight { consume-or-expel-window-right; }

    // Consume one window from the right to the bottom of the focused column.
    Mod+Comma  { consume-window-into-column; }
    // Expel the bottom window from the focused column to the right.
    Mod+Period { expel-window-from-column; }

    // Cycle through widths set in preset-column-widths.
    Mod+R { switch-preset-column-width; }
    // Cycling through the presets in reverse order is also possible.
    Mod+Shift+R { switch-preset-column-width-back; }

    Mod+Ctrl+Shift+R { switch-preset-window-height; }
    Mod+Ctrl+R { reset-window-height; }

    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }

    // While maximize-column leaves gaps and borders around the window,
    // maximize-window-to-edges doesn't: the window expands to the edges of the screen.
    // This bind corresponds to normal window maximizing,
    // e.g. by double-clicking on the titlebar.
    Mod+M { maximize-window-to-edges; }

    // Expand the focused column to space not taken up by other fully visible columns.
    // Makes the column "fill the rest of the space".
    Mod+Ctrl+F { expand-column-to-available-width; }

    Mod+C { center-column; }

    // Center all fully visible columns on screen.
    Mod+Ctrl+C { center-visible-columns; }

    // Finer width adjustments.
    // This command can also:
    // * set width in pixels: "1000"
    // * adjust width in pixels: "-5" or "+5"
    // * set width as a percentage of screen width: "25%"
    // * adjust width as a percentage of screen width: "-10%" or "+10%"
    // Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
    // set-column-width "100" will make the column occupy 200 physical screen pixels.
    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }

    // Finer height adjustments when in column with other windows.
    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }

    // Move the focused window between the floating and the tiling layout.
    Mod+V       { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    // Toggle tabbed column display mode.
    // Windows in this column will appear as vertical tabs,
    // rather than stacked on top of each other.
    Mod+W { toggle-column-tabbed-display; }

    // Actions to switch layouts.
    // Note: if you uncomment these, make sure you do NOT have
    // a matching layout switch hotkey configured in xkb options above.
    // Having both at once on the same hotkey will break the switching,
    // since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
    // Mod+Space       { switch-layout "next"; }
    // Mod+Shift+Space { switch-layout "prev"; }

    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }

    // Applications such as remote-desktop clients and software KVM switches may
    // request that niri stops processing the keyboard shortcuts defined here
    // so they may, for example, forward the key presses as-is to a remote machine.
    // It's a good idea to bind an escape hatch to toggle the inhibitor,
    // so a buggy application can't hold your session hostage.
    //
    // The allow-inhibiting=false property can be applied to other binds as well,
    // which ensures niri always processes them, even when an inhibitor is active.
    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    // The quit action will show a confirmation dialog to avoid accidental exits.
    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    // Powers off the monitors. To turn them back on, do any input like
    // moving the mouse or pressing any other key.
    Mod+Shift+P { power-off-monitors; }
}

```


## Introduction


### Per-Section Documentation

You can find documentation for various sections of the config on these wiki pages:

* [`input {}`](https://niri-wm.github.io/niri/Configuration%3A-Input.html)
* [`output "eDP-1" {}`](https://niri-wm.github.io/niri/Configuration%3A-Outputs.html)
* [`binds {}`](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html)
* [`switch-events {}`](https://niri-wm.github.io/niri/Configuration%3A-Switch-Events.html)
* [`layout {}`](https://niri-wm.github.io/niri/Configuration%3A-Layout.html)
* [top-level options](https://niri-wm.github.io/niri/Configuration%3A-Miscellaneous.html)
* [`window-rule {}`](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html)
* [`layer-rule {}`](https://niri-wm.github.io/niri/Configuration%3A-Layer-Rules.html)
* [`animations {}`](https://niri-wm.github.io/niri/Configuration%3A-Animations.html)
* [`gestures {}`](https://niri-wm.github.io/niri/Configuration%3A-Gestures.html)
* [`recent-windows {}`](https://niri-wm.github.io/niri/Configuration%3A-Recent-Windows.html)
* [`debug {}`](https://niri-wm.github.io/niri/Configuration%3A-Debug-Options.html)
* [`include "other.kdl"`](https://niri-wm.github.io/niri/Configuration%3A-Include.html)

### Loading

Niri will load configuration from `$XDG_CONFIG_HOME/niri/config.kdl` or `~/.config/niri/config.kdl`, falling back to `/etc/niri/config.kdl`.
If both of these files are missing, niri will create `$XDG_CONFIG_HOME/niri/config.kdl` with the contents of [the default configuration file](https://github.com/niri-wm/niri/blob/main/resources/default-config.kdl), which are embedded into the niri binary at build time.
Please use the default configuration file as the starting point for your custom configuration.

The configuration is live-reloaded.
Simply edit and save the config file, and your changes will be applied.
This includes key bindings, output settings like mode, window rules, and everything else.

You can run `niri validate` to parse the config and see any errors.

To use a different config file path, pass it in the `--config` or `-c` argument to `niri`.

You can also set `$NIRI_CONFIG` to the path of the config file.
`--config` always takes precedence.
If `--config` or `$NIRI_CONFIG` doesn't point to a real file, the config will not be loaded.
If `$NIRI_CONFIG` is set to an empty string, it is ignored and the default config location is used instead.

### Syntax

The config is written in [KDL].

#### Comments

Lines starting with `//` are comments; they are ignored.

Also, you can put `/-` in front of a section to comment out the entire section:

```kdl
/-output "eDP-1" {
    // Everything inside here is ignored.
    // The display won't be turned off
    // as the whole section is commented out.
    off
}
```

#### Flags

Toggle options in niri are commonly represented as flags.
Writing out the flag enables it, and omitting it or commenting it out disables it.
For example:

```kdl
// "Focus follows mouse" is enabled.
input {
    focus-follows-mouse

    // Other settings...
}
```

```kdl
// "Focus follows mouse" is disabled.
input {
    // focus-follows-mouse

    // Other settings...
}
```

#### Sections

Most sections cannot be repeated. For example:

```kdl
// This is valid: every section appears once.
input {
    keyboard {
        // ...
    }

    touchpad {
        // ...
    }
}
```

```kdl,must-fail
// This is NOT valid: input section appears twice.
input {
    keyboard {
        // ...
    }
}

input {
    touchpad {
        // ...
    }
}
```

Exceptions are, for example, sections that configure different devices by name:

<!-- NOTE: this may break in the future -->
```kdl
output "eDP-1" {
    // ...
}

// This is valid: this section configures a different output.
output "HDMI-A-1" {
    // ...
}

// This is NOT valid: "eDP-1" already appeared above.
// It will either throw a config parsing error, or otherwise not work.
output "eDP-1" {
    // ...
}
```

### Defaults

Omitting most of the sections of the config file will leave you with the default values for that section.
A notable exception is [`binds {}`](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html): they do not get filled with defaults, so make sure you do not erase this section.

### Breaking Change Policy

As a rule, niri updates should not break existing config files.
(For example, the default config from niri v0.1.0 still parses fine on v25.02 as I'm writing this.)

Exceptions can be made for parsing bugs.
For example, niri used to accept multiple binds to the same key, but this was not intended and did not do anything (the first bind was always used).
A patch release changed niri from silently accepting this to causing a parsing failure.
This is not a blanket rule, I will consider the potential impact of every breaking change like this before deciding to carry on with it.

Keep in mind that the breaking change policy applies only to niri releases.
Commits between releases can and do occasionally break the config as new features are ironed out.
However, I do try to limit these, since several people are running git builds.

[KDL]: https://kdl.dev/



## Input


### Overview

In this section you can configure input devices like keyboard and mouse, and some input-related options.

There's a section for each device type: `keyboard`, `touchpad`, `mouse`, `trackpoint`, `trackball`, `tablet`, `touch`.
Settings in those sections will apply to every device of that type.
Currently, there's no way to configure specific devices individually (but that is planned).

All settings at a glance:

```kdl
input {
    keyboard {
        xkb {
            // layout "us"
            // variant "colemak_dh_ortho"
            // options "compose:ralt,ctrl:nocaps"
            // model ""
            // rules ""
            // file "~/.config/keymap.xkb"
        }

        // repeat-delay 600
        // repeat-rate 25
        // track-layout "global"
        numlock
    }

    touchpad {
        // off
        tap
        // dwt
        // dwtp
        // drag false
        // drag-lock
        natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-factor 1.0
        // scroll-factor vertical=1.0 horizontal=-2.0
        // scroll-method "two-finger"
        // scroll-button 273
        // scroll-button-lock
        // tap-button-map "left-middle-right"
        // click-method "clickfinger"
        // left-handed
        // disabled-on-external-mouse
        // middle-emulation
    }

    mouse {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-factor 1.0
        // scroll-factor vertical=1.0 horizontal=-2.0
        // scroll-method "no-scroll"
        // scroll-button 273
        // scroll-button-lock
        // left-handed
        // middle-emulation
    }

    trackpoint {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // scroll-button-lock
        // left-handed
        // middle-emulation
    }

    trackball {
        // off
        // natural-scroll
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-method "on-button-down"
        // scroll-button 273
        // scroll-button-lock
        // left-handed
        // middle-emulation
    }

    tablet {
        // off
        map-to-output "eDP-1"
        // map-to-focused-output
        // left-handed
        // calibration-matrix 1.0 0.0 0.0 0.0 1.0 0.0
    }

    touch {
        // off
        map-to-output "eDP-1"
        // calibration-matrix 1.0 0.0 0.0 0.0 1.0 0.0
    }

    // disable-power-key-handling
    // warp-mouse-to-focus
    // focus-follows-mouse max-scroll-amount="0%"
    // workspace-auto-back-and-forth

    // mod-key "Super"
    // mod-key-nested "Alt"
}
```

### Keyboard

#### Layout

In the `xkb` section, you can set layout, variant, options, model and rules.
These are passed directly to libxkbcommon, which is also used by most other Wayland compositors.
See the `xkeyboard-config(7)` manual for more information.

```kdl
input {
    keyboard {
        xkb {
            layout "us"
            variant "colemak_dh_ortho"
            options "compose:ralt,ctrl:nocaps"
        }
    }
}
```

> [!TIP]
>
> <sup>Since: 25.02</sup>
>
> Alternatively, you can directly set a path to a .xkb file containing an xkb keymap.
> This overrides all other xkb settings.
>
> ```kdl
> input {
>     keyboard {
>         xkb {
>             file "~/.config/keymap.xkb"
>         }
>     }
> }
> ```

> [!NOTE]
>
> <sup>Since: 25.08</sup>
>
> If the `xkb` section is empty (like it is by default), niri will fetch xkb settings from systemd-localed at `org.freedesktop.locale1` over D-Bus.
> This way, for example, system installers can dynamically set the niri keyboard layout.
> You can see this layout in `localectl` and change it with `localectl set-x11-keymap`, for example:
>
> ```sh
> $ localectl set-x11-keymap "us" "" "colemak_dh_ortho" "compose:ralt,ctrl:nocaps"
> $ localectl
> System Locale: LANG=en_US.UTF-8
>                LC_NUMERIC=ru_RU.UTF-8
>                LC_TIME=ru_RU.UTF-8
>                LC_MONETARY=ru_RU.UTF-8
>                LC_PAPER=ru_RU.UTF-8
>                LC_MEASUREMENT=ru_RU.UTF-8
>     VC Keymap: us-colemak_dh_ortho
>    X11 Layout: us
>   X11 Variant: colemak_dh_ortho
>   X11 Options: compose:ralt,ctrl:nocaps
> ```
>
> By default, `localectl` will set the TTY keymap to the closest match of the XKB keymap.
> You can prevent that with a `--no-convert` flag, for example: `localectl set-x11-keymap --no-convert "us,ru"`.
>
> These settings are picked up by some other programs too, like GDM.

When using multiple layouts, niri can remember the current layout globally (the default) or per-window.
You can control this with the `track-layout` option.

- `global`: layout change is global for all windows.
- `window`: layout is tracked for each window individually.

```kdl
input {
    keyboard {
        track-layout "global"
    }
}
```

#### Repeat

Delay is in milliseconds before the keyboard repeat starts.
Rate is in characters per second.

```kdl
input {
    keyboard {
        repeat-delay 600
        repeat-rate 25
    }
}
```

#### Num Lock

<sup>Since: 25.05</sup>

Set the `numlock` flag to turn on Num Lock automatically at startup.

You might want to disable (comment out) `numlock` if you're using a laptop with a keyboard that overlays Num Lock keys on top of regular keys.

```kdl
input {
    keyboard {
        numlock
    }
}
```

### Pointing Devices

Most settings for the pointing devices are passed directly to libinput.
Other Wayland compositors also use libinput, so it's likely you will find the same settings there.
For flags like `tap`, omit them or comment them out to disable the setting.

A few settings are common between input devices:

- `off`: if set, no events will be sent from this device.

A few settings are common between `touchpad`, `mouse`, `trackpoint`, and `trackball`:

- `natural-scroll`: if set, inverts the scrolling direction.
- `accel-speed`: pointer acceleration speed, valid values are from `-1.0` to `1.0` where the default is `0.0`.
- `accel-profile`: can be `adaptive` (the default) or `flat` (disables pointer acceleration).
- `scroll-method`: when to generate scroll events instead of pointer motion events, can be `no-scroll`, `two-finger`, `edge`, or `on-button-down`.
  The default and supported methods vary depending on the device type.
- `scroll-button`: <sup>Since: 0.1.10</sup> the button code used for the `on-button-down` scroll method. You can find it in `libinput debug-events`.
- `scroll-button-lock`: <sup>Since: 25.08</sup> when enabled, the button does not need to be held down. Pressing once engages scrolling, pressing a second time disengages it, and double click acts as single click of the the underlying button.
- `left-handed`: if set, changes the device to left-handed mode.
- `middle-emulation`: emulate a middle mouse click by pressing left and right mouse buttons at once.

Settings specific to `touchpad`s:

- `tap`: tap-to-click.
- `dwt`: disable-when-typing.
- `dwtp`: disable-when-trackpointing.
- `drag`: <sup>Since: 25.05</sup> can be `true` or `false`, controls if tap-and-drag is enabled.
- `drag-lock`: <sup>Since: 25.02</sup> if set, lifting the finger off for a short time while dragging will not drop the dragged item. See the [libinput documentation](https://wayland.freedesktop.org/libinput/doc/latest/tapping.html#tap-and-drag).
- `tap-button-map`: can be `left-right-middle` or `left-middle-right`, controls which button corresponds to a two-finger tap and a three-finger tap.
- `click-method`: can be `button-areas` or `clickfinger`, changes the [click method](https://wayland.freedesktop.org/libinput/doc/latest/clickpad-softbuttons.html).
- `disabled-on-external-mouse`: do not send events while external pointer device is plugged in.

Settings specific to `touchpad` and `mouse`:

- `scroll-factor`: <sup>Since: 0.1.10</sup> scales the scrolling speed by this value.

    <sup>Since: 25.08</sup> You can also override horizontal and vertical scroll factor separately like so: `scroll-factor horizontal=2.0 vertical=-1.0`

Settings specific to `tablet` and `touch`:

- `calibration-matrix`: set to six floating point numbers to change the calibration matrix. See the [`LIBINPUT_CALIBRATION_MATRIX` documentation](https://wayland.freedesktop.org/libinput/doc/latest/device-configuration-via-udev.html) for examples.
    - <sup>Since: 25.02</sup> for `tablet`
    - <sup>Since: 25.11</sup> for `touch`

Tablets and touchscreens are absolute pointing devices that can be mapped to a specific output like so:

```kdl
input {
    tablet {
        map-to-output "eDP-1"
    }

    touch {
        map-to-output "eDP-1"
    }
}
```

Valid output names are the same as the ones used for output configuration.

<sup>Since: 0.1.7</sup> When a tablet is not mapped to any output, it will map to the union of all connected outputs, without aspect ratio correction.

Setting specific to `tablet`:

- `map-to-focused-output`: <sup>Since: 26.04</sup> will map the tablet to the focused output, takes precedence over `map-to-output`.

### General Settings

These settings are not specific to a particular input device.

#### `disable-power-key-handling`

By default, niri will take over the power button to make it sleep instead of power off.
Set this if you would like to configure the power button elsewhere (i.e. `logind.conf`).

```kdl
input {
    disable-power-key-handling
}
```

#### `warp-mouse-to-focus`

Makes the mouse warp to newly focused windows.

Does not make the cursor visible if it had been hidden.

```kdl
input {
    warp-mouse-to-focus
}
```

By default, the cursor warps *separately* horizontally and vertically.
I.e. if moving the mouse only horizontally is enough to put it inside the newly focused window, then the mouse will move only horizontally, and not vertically.

<sup>Since: 25.05</sup> You can customize this with the `mode` property.

- `mode="center-xy"`: warps by both X and Y coordinates together.
So if the mouse was anywhere outside the newly focused window, it will warp to the center of the window.
- `mode="center-xy-always"`: warps by both X and Y coordinates together, even if the mouse was already somewhere inside the newly focused window.

```kdl
input {
    warp-mouse-to-focus mode="center-xy"
}
```

#### `focus-follows-mouse`

Focuses windows and outputs automatically when moving the mouse over them.

```kdl
input {
    focus-follows-mouse
}
```

<sup>Since: 0.1.8</sup> You can optionally set `max-scroll-amount`.
Then, focus-follows-mouse won't focus a window if it will result in the view scrolling more than the set amount.
The value is a percentage of the working area width.

```kdl
input {
    // Allow focus-follows-mouse when it results in scrolling at most 10% of the screen.
    focus-follows-mouse max-scroll-amount="10%"
}
```

```kdl
input {
    // Allow focus-follows-mouse only when it will not scroll the view.
    focus-follows-mouse max-scroll-amount="0%"
}
```

#### `workspace-auto-back-and-forth`

Normally, switching to the same workspace by index twice will do nothing (since you're already on that workspace).
If this flag is enabled, switching to the same workspace by index twice will switch back to the previous workspace.

Niri will correctly switch to the workspace you came from, even if workspaces were reordered in the meantime.

```kdl
input {
    workspace-auto-back-and-forth
}
```

#### `mod-key`, `mod-key-nested`

<sup>Since: 25.05</sup>

Customize the `Mod` key for [key bindings](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html).
Only valid modifiers are allowed, e.g. `Super`, `Alt`, `Mod3`, `Mod5`, `Ctrl`, `Shift`.

By default, `Mod` is equal to `Super` when running niri on a TTY, and to `Alt` when running niri as a nested winit window.

> [!NOTE]
> There are a lot of default bindings with Mod, none of them "make it through" to the underlying window.
> You probably don't want to set `mod-key` to Ctrl or Shift, since Ctrl is commonly used for app hotkeys, and Shift is used for, well, regular typing.

```kdl
// Switch the mod keys around: use Alt normally, and Super inside a nested window.
input {
    mod-key "Alt"
    mod-key-nested "Super"
}
```



## Outputs


### Overview

By default, niri will attempt to turn on all connected monitors using their preferred modes.
You can disable or adjust this with `output` sections.

Here's what it looks like with all properties written out:

```kdl
output "eDP-1" {
    // off
    mode "1920x1080@120.030"
    scale 2.0
    transform "90"
    position x=1280 y=0
    variable-refresh-rate // on-demand=true
    focus-at-startup
    backdrop-color "#001100"

    hot-corners {
        // off
        top-left
        // top-right
        // bottom-left
        // bottom-right
    }

    layout {
        // ...layout settings for eDP-1...
    }

    // Custom modes. Caution: may damage your display.
    // mode custom=true "1920x1080@100"
    // modeline 173.00  1920 2048 2248 2576  1080 1083 1088 1120 "-hsync" "+vsync"
}

output "HDMI-A-1" {
    // ...settings for HDMI-A-1...
}

output "Some Company CoolMonitor 1234" {
    // ...settings for CoolMonitor...
}
```

Outputs are matched by connector name (i.e. `eDP-1`, `HDMI-A-1`), or by monitor manufacturer, model, and serial, separated by a single space each.
You can find all of these by running `niri msg outputs`.

Usually, the built-in monitor in laptops will be called `eDP-1`.

<sup>Since: 0.1.6</sup> The output name is case-insensitive.

<sup>Since: 0.1.9</sup> Outputs can be matched by manufacturer, model, and serial.
Before, they could be matched only by the connector name.

### `off`

This flag turns off that output entirely.

```kdl
// Turn off that monitor.
output "HDMI-A-1" {
    off
}
```

### `mode`

Set the monitor resolution and refresh rate.

The format is `<width>x<height>` or `<width>x<height>@<refresh rate>`.
If the refresh rate is omitted, niri will pick the highest refresh rate for the resolution.

If the mode is omitted altogether or doesn't work, niri will try to pick one automatically.

Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
The refresh rate that you set here must match *exactly*, down to the three decimal digits, to what you see in `niri msg outputs`.

```kdl
// Set a high refresh rate for this monitor.
// High refresh rate monitors tend to use 60 Hz as their preferred mode,
// requiring a manual mode setting.
output "HDMI-A-1" {
    mode "2560x1440@143.912"
}

// Use a lower resolution on the built-in laptop monitor
// (for example, for testing purposes).
output "eDP-1" {
    mode "1280x720"
}
```

#### `mode custom=true`

<sup>Since: 25.11</sup>

You can configure a custom mode (not offered by the monitor) by setting `custom=true`.
In this case, the refresh rate is mandatory.

Custom modes are not guaranteed to work.
Niri is asking the monitor to run in a mode that is not supported by the manufacturer.
Use at your own risk.

> [!CAUTION]
> Custom modes may damage your monitor, especially if it's a CRT.
> Follow the maximum supported limits in your monitor's instructions.

```kdl
// Use a custom mode for this display.
output "HDMI-A-1" {
    mode custom=true "2560x1440@143.912"
}
```

### `modeline`

<sup>Since: 25.11</sup>

Directly configures the monitor's mode via a modeline, overriding any configured `mode`.
The modeline can be calculated via utilities such as [cvt](https://man.archlinux.org/man/cvt.1.en) or [gtf](https://man.archlinux.org/man/gtf.1.en).

Modelines are not guaranteed to work.
Niri is asking the monitor to run in a mode not supported by the manufacturer.
Use at your own risk.

> [!CAUTION]
> Out of spec modelines may damage your monitor, especially if it's a CRT.
> Follow the maximum supported limits in your monitor's instructions.

```kdl
// Use a modeline for this display.
output "eDP-3" {
    modeline 173.00  1920 2048 2248 2576  1080 1083 1088 1120 "-hsync" "+vsync"
}
```

### `scale`

Set the scale of the monitor.

<sup>Since: 0.1.6</sup> If scale is unset, niri will guess an appropriate scale based on the physical dimensions and the resolution of the monitor.

<sup>Since: 0.1.7</sup> You can use fractional scale values, for example `scale 1.5` for 150% scale.

<sup>Since: 0.1.7</sup> Dot is no longer needed for integer scale, for example you can write `scale 2` instead of `scale 2.0`.

<sup>Since: 0.1.7</sup> Scale below 0 and above 10 will now fail during config parsing. Scale was previously clamped to these values anyway.

```kdl
output "eDP-1" {
    scale 2.0
}
```

### `transform`

Rotate the output counter-clockwise.

Valid values are: `"normal"`, `"90"`, `"180"`, `"270"`, `"flipped"`, `"flipped-90"`, `"flipped-180"` and `"flipped-270"`.
Values with `flipped` additionally flip the output.

```kdl
output "HDMI-A-1" {
    transform "90"
}
```

### `position`

Set the position of the output in the global coordinate space.

This affects directional monitor actions like `focus-monitor-left`, and cursor movement.
The cursor can only move between directly adjacent outputs.

> [!NOTE]
> Output scale and rotation has to be taken into account for positioning: outputs are sized in logical, or scaled, pixels.
> For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080, so to put another output directly adjacent to it on the right, set its x to 1920.
> If the position is unset or results in an overlap, the output is instead placed automatically.

```kdl
output "HDMI-A-1" {
    position x=1280 y=0
}
```

#### Automatic Positioning

Niri repositions outputs from scratch every time the output configuration changes (which includes monitors disconnecting and connecting).
The following algorithm is used for positioning outputs.

1. Collect all connected monitors and their logical sizes.
1. Sort them by their name. This makes it so the automatic positioning does not depend on the order the monitors are connected. This is important because the connection order is non-deterministic at compositor startup.
1. Try to place every output with explicitly configured `position`, in order. If the output overlaps previously placed outputs, place it to the right of all previously placed outputs. In this case, niri will also print a warning.
1. Place every output without explicitly configured `position` by putting it to the right of all previously placed outputs.

### `variable-refresh-rate`

<sup>Since: 0.1.5</sup>

This flag enables variable refresh rate (VRR, also known as adaptive sync, FreeSync, or G-Sync), if the output supports it.

You can check whether an output supports VRR in `niri msg outputs`.

> [!NOTE]
> Some drivers have various issues with VRR.
>
> If the cursor moves at a low framerate with VRR, try setting the [`disable-cursor-plane` debug flag](https://niri-wm.github.io/niri/Configuration%3A-Debug-Options.html#disable-cursor-plane) and reconnecting the monitor.
>
> If a monitor is not detected as VRR-capable when it should, sometimes unplugging a different monitor fixes it.
>
> Some monitors will continuously modeset (flash black) with VRR enabled; I'm not sure if there's a way to fix it.

```kdl
output "HDMI-A-1" {
    variable-refresh-rate
}
```

<sup>Since: 0.1.9</sup> You can also set the `on-demand=true` property, which will only enable VRR when this output shows a window matching the `variable-refresh-rate` window rule.
This is helpful to avoid various issues with VRR, since it can be disabled most of the time, and only enabled for specific windows, like games or video players.

```kdl
output "HDMI-A-1" {
    variable-refresh-rate on-demand=true
}
```

### `focus-at-startup`

<sup>Since: 25.05</sup>

Focus this output by default when niri starts.

If multiple outputs with `focus-at-startup` are connected, they are prioritized in the order that they appear in the config.

When none of the connected outputs are explicitly `focus-at-startup`, niri will focus the first one sorted by name (same output sorting as used elsewhere in niri).

```kdl
// Focus HDMI-A-1 by default.
output "HDMI-A-1" {
    focus-at-startup
}

// ...if HDMI-A-1 wasn't connected, focus DP-2 instead.
output "DP-2" {
    focus-at-startup
}
```

### `background-color`

<sup>Since: 0.1.8</sup>

Set the background color that niri draws for workspaces on this output.
This is visible when you're not using any background tools like swaybg.

<sup>Until: 25.05</sup> The alpha channel for this color will be ignored.

<sup>Since: 25.11</sup> This setting is deprecated, set `background-color` in the [output `layout {}` block](#layout-config-overrides) instead.

```kdl
output "HDMI-A-1" {
    background-color "#003300"
}
```

### `backdrop-color`

<sup>Since: 25.05</sup>

Set the backdrop color that niri draws for this output.
This is visible between workspaces or in the overview.

The alpha channel for this color will be ignored.

```kdl
output "HDMI-A-1" {
    backdrop-color "#001100"
}
```

### `hot-corners`

<sup>Since: 25.11</sup>

Customize the hot corners for this output.
By default, hot corners [in the gestures settings](https://niri-wm.github.io/niri/Configuration%3A-Gestures.html#hot-corners) are used for all outputs.

Hot corners toggle the overview when you put your mouse at the very corner of a monitor.

`off` will disable the hot corners on this output, and writing specific corners will enable only those hot corners on this output.

```kdl
// Enable the bottom-left and bottom-right hot corners on HDMI-A-1.
output "HDMI-A-1" {
    hot-corners {
        bottom-left
        bottom-right
    }
}

// Disable the hot corners on DP-2.
output "DP-2" {
    hot-corners {
        off
    }
}
```

### Layout config overrides

<sup>Since: 25.11</sup>

You can customize layout settings for an output with a `layout {}` block:

```kdl
output "SomeCompany VerticalMonitor 1234" {
    transform "90"

    // Layout config overrides just for this output.
    layout {
        default-column-width { proportion 1.0; }

        // ...any other setting.
    }
}

output "SomeCompany UltrawideMonitor 1234" {
    // Narrower proportions and more presets for an ultrawide.
    layout {
        default-column-width { proportion 0.25; }

        preset-column-widths {
            proportion 0.2
            proportion 0.25
            proportion 0.5
            proportion 0.75
            proportion 0.8
        }
    }
}
```

It accepts all the same options as [the top-level `layout {}` block](https://niri-wm.github.io/niri/Configuration%3A-Layout.html).

In order to unset a flag, write it with `false`, e.g.:

```kdl
layout {
    // Enabled globally.
    always-center-single-column
}

output "eDP-1" {
    layout {
        // Unset on this output.
        always-center-single-column false
    }
}
```



## Key Bindings


### Overview

Key bindings are declared in the `binds {}` section of the config.

> [!NOTE]
> This is one of the few sections that *does not* get automatically filled with defaults if you omit it, so make sure to copy it from the default config.

Each bind is a hotkey followed by one action enclosed in curly brackets.
For example:

```kdl
binds {
    Mod+Left { focus-column-left; }
    Super+Alt+L { spawn "swaylock"; }
}
```

The hotkey consists of modifiers separated by `+` signs, followed by an XKB key name in the end.

Valid modifiers are:

- `Ctrl` or `Control`;
- `Shift`;
- `Alt`;
- `Super` or `Win`;
- `ISO_Level3_Shift` or `Mod5`—this is the AltGr key on certain layouts;
- `ISO_Level5_Shift`: can be used with an xkb lv5 option like `lv5:caps_switch`;
- `Mod`.

`Mod` is a special modifier that is equal to `Super` when running niri on a TTY, and to `Alt` when running niri as a nested winit window.
This way, you can test niri in a window without causing too many conflicts with the host compositor's key bindings.
For this reason, most of the default keys use the `Mod` modifier.

<sup>Since: 25.05</sup> You can customize the `Mod` key [in the `input` section of the config](https://niri-wm.github.io/niri/Configuration%3A-Input.html#mod-key-mod-key-nested).

> [!TIP]
> To find an XKB name for a particular key, you may use a program like [`wev`](https://git.sr.ht/~sircmpwn/wev).
>
> Open it from a terminal and press the key that you want to detect.
> In the terminal, you will see output like this:
>
> ```
> [14:     wl_keyboard] key: serial: 757775; time: 44940343; key: 113; state: 1 (pressed)
>                       sym: Left         (65361), utf8: ''
> [14:     wl_keyboard] key: serial: 757776; time: 44940432; key: 113; state: 0 (released)
>                       sym: Left         (65361), utf8: ''
> [14:     wl_keyboard] key: serial: 757777; time: 44940753; key: 114; state: 1 (pressed)
>                       sym: Right        (65363), utf8: ''
> [14:     wl_keyboard] key: serial: 757778; time: 44940846; key: 114; state: 0 (released)
>                       sym: Right        (65363), utf8: ''
> ```
>
> Here, look at `sym: Left` and `sym: Right`: these are the key names.
> I was pressing the left and the right arrow in this example.
>
> Keep in mind that binding shifted keys requires spelling out Shift and the unshifted version of the key, according to your XKB layout.
> For example, on the US QWERTY layout, <kbd>&lt;</kbd> is on <kbd>Shift</kbd> + <kbd>,</kbd>, so to bind it, you spell out something like `Mod+Shift+Comma`.
>
> As another example, if you've configured the French [BÉPO](https://en.wikipedia.org/wiki/B%C3%89PO) XKB layout, your <kbd>&lt;</kbd> is on <kbd>AltGr</kbd> + <kbd>«</kbd>.
> <kbd>AltGr</kbd> is `ISO_Level3_Shift`, or equivalently `Mod5`, so to bind it, you spell out something like `Mod+Mod5+guillemotleft`.
>
> When resolving latin keys, niri will search for the *first* configured XKB layout that has the latin key.
> So for example with US QWERTY and RU layouts configured, US QWERTY will be used for latin binds.

<sup>Since: 0.1.8</sup> Binds will repeat by default (i.e. holding down a bind will make it trigger repeatedly).
You can disable that for specific binds with `repeat=false`:

```kdl
binds {
    Mod+T repeat=false { spawn "alacritty"; }
}
```

Binds can also have a cooldown, which will rate-limit the bind and prevent it from repeatedly triggering too quickly.

```kdl
binds {
    Mod+T cooldown-ms=500 { spawn "alacritty"; }
}
```

This is mostly useful for the scroll bindings.

### Scroll Bindings

You can bind mouse wheel scroll ticks using the following syntax.
These binds will change direction based on the `natural-scroll` setting.

```kdl
binds {
    Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp   cooldown-ms=150 { focus-workspace-up; }
    Mod+WheelScrollRight                { focus-column-right; }
    Mod+WheelScrollLeft                 { focus-column-left; }
}
```

Similarly, you can bind touchpad scroll "ticks".
Touchpad scrolling is continuous, so for these binds it is split into discrete intervals based on distance travelled.

These binds are also affected by touchpad's `natural-scroll`, so these example binds are "inverted", since niri has `natural-scroll` enabled for touchpads by default.

```kdl
binds {
    Mod+TouchpadScrollDown { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02+"; }
    Mod+TouchpadScrollUp   { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.02-"; }
}
```

Both mouse wheel and touchpad scroll binds will prevent applications from receiving any scroll events when their modifiers are held down.
For example, if you have a `Mod+WheelScrollDown` bind, then while holding `Mod`, all mouse wheel scrolling will be consumed by niri.

### Mouse Click Bindings

<sup>Since: 25.01</sup>

You can bind mouse clicks using the following syntax.

```kdl
binds {
    Mod+MouseLeft    { close-window; }
    Mod+MouseRight   { close-window; }
    Mod+MouseMiddle  { close-window; }
    Mod+MouseForward { close-window; }
    Mod+MouseBack    { close-window; }
}
```

Mouse clicks operate on the window that was focused at the time of the click, not the window you're clicking.

Note that binding `Mod+MouseLeft` or `Mod+MouseRight` will override the corresponding gesture (moving or resizing the window).

### Custom Hotkey Overlay Titles

<sup>Since: 25.02</sup>

The hotkey overlay (the Important Hotkeys dialog) shows a hardcoded list of binds.
You can customize this list using the `hotkey-overlay-title` property.

To add a bind to the hotkey overlay, set the property to the title that you want to show:
```kdl
binds {
    Mod+Shift+S hotkey-overlay-title="Toggle Dark/Light Style" { spawn "some-script.sh"; }
}
```

Binds with custom titles are listed after the hardcoded binds and before non-customized Spawn binds.

To remove a hardcoded bind from the hotkey overlay, set the property to null:
```kdl
binds {
    Mod+Q hotkey-overlay-title=null { close-window; }
}
```

> [!TIP]
> When multiple key combinations are bound to the same action:
> - If any of the binds has a custom hotkey overlay title, niri will show that bind.
> - Otherwise, if any of the binds has a null title, niri will hide the bind.
> - Otherwise, niri will show the first key combination.

Custom titles support [Pango markup](https://docs.gtk.org/Pango/pango_markup.html):

```kdl
binds {
    Mod+Shift+S hotkey-overlay-title="<b>Toggle</b> <span foreground='red'>Dark</span>/Light Style" { spawn "some-script.sh"; }
}
```

![Custom markup example.](https://github.com/user-attachments/assets/2a2ba914-bfa7-4dfa-bb5e-49839034765d)

### Actions

Every action that you can bind is also available for programmatic invocation via `niri msg action`.
Run `niri msg action` to get a full list of actions along with their short descriptions.

Here are a few actions that benefit from more explanation.

#### `spawn`

Run a program.

`spawn` accepts a path to the program binary as the first argument, followed by arguments to the program.
For example:

```kdl
binds {
    // Run alacritty.
    Mod+T { spawn "alacritty"; }

    // Run `wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+`.
    XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
}
```

> [!TIP]
>
> <sup>Since: 0.1.5</sup>
>
> Spawn bindings have a special `allow-when-locked=true` property that makes them work even while the session is locked:
>
> ```kdl
> binds {
>     // This mute bind will work even when the session is locked.
>     XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
> }
> ```

For `spawn`, niri *does not* use a shell to run commands, which means that you need to manually separate arguments.
See [`spawn-sh`](#spawn-sh) below for an action that uses a shell.

```kdl
binds {
    // Correct: every argument is in its own quotes.
    Mod+T { spawn "alacritty" "-e" "/usr/bin/fish"; }

    // Wrong: will interpret the whole `alacritty -e /usr/bin/fish` string as the binary path.
    Mod+D { spawn "alacritty -e /usr/bin/fish"; }

    // Wrong: will pass `-e /usr/bin/fish` as one argument, which alacritty won't understand.
    Mod+Q { spawn "alacritty" "-e /usr/bin/fish"; }
}
```

This also means that you cannot expand environment variables or `~`.
If you need this, you can run the command through a shell manually.

```kdl
binds {
    // Wrong: no shell expansion here. These strings will be passed literally to the program.
    Mod+T { spawn "grim" "-o" "$MAIN_OUTPUT" "~/screenshot.png"; }

    // Correct: run this through a shell manually so that it can expand the arguments.
    // Note that the entire command is passed as a SINGLE argument,
    // because shell will do its own argument splitting by whitespace.
    Mod+D { spawn "sh" "-c" "grim -o $MAIN_OUTPUT ~/screenshot.png"; }

    // You can also use a shell to run multiple commands,
    // use pipes, process substitution, and so on.
    Mod+Q { spawn "sh" "-c" "notify-send clipboard \"$(wl-paste)\""; }
}
```

As a special case, niri will expand `~` to the home directory *only* at the beginning of the program name.

```kdl
binds {
    // This will work: one ~ at the very beginning.
    Mod+T { spawn "~/scripts/do-something.sh"; }
}
```

#### `spawn-sh`

<sup>Since: 25.08</sup>

Run a command through the shell.

The argument is a single string that is passed verbatim to `sh`.
You can use shell variables, pipelines, `~` expansion, and everything else as expected.

```kdl
binds {
    // Works with spawn-sh: all arguments in the same string.
    Mod+D { spawn-sh "alacritty -e /usr/bin/fish"; }

    // Works with spawn-sh: shell variable ($MAIN_OUTPUT), ~ expansion.
    Mod+T { spawn-sh "grim -o $MAIN_OUTPUT ~/screenshot.png"; }

    // Works with spawn-sh: process substitution.
    Mod+Q { spawn-sh "notify-send clipboard \"$(wl-paste)\""; }

    // Works with spawn-sh: multiple commands.
    Super+Alt+S { spawn-sh "pkill orca || exec orca"; }
}
```

`spawn-sh "some command"` is equivalent to `spawn "sh" "-c" "some command"`—it's just a less confusing shorthand.
Keep in mind that going through the shell incurs a tiny performance penalty compared to directly `spawn`ing some binary.

Using `sh` is hardcoded, consistent with other compositors.
If you want a different shell, write it out using `spawn`, e.g. `spawn "fish" "-c" "some fish command"`.

#### `quit`

Exit niri after showing a confirmation dialog to avoid accidentally triggering it.

```kdl
binds {
    Mod+Shift+E { quit; }
}
```

If you want to skip the confirmation dialog, set the flag like so:

```kdl
binds {
    Mod+Shift+E { quit skip-confirmation=true; }
}
```

#### `do-screen-transition`

<sup>Since: 0.1.6</sup>

Freeze the screen for a brief moment then crossfade to the new contents.

```kdl
binds {
    Mod+Return { do-screen-transition; }
}
```

This action is mainly useful to trigger from scripts changing the system theme or style (between light and dark for example).
It makes transitions like this, where windows change their style one by one, look smooth and synchronized.

For example, using the GNOME color scheme setting:

```shell
niri msg action do-screen-transition
dconf write /org/gnome/desktop/interface/color-scheme "\"prefer-dark\""
```

By default, the screen is frozen for 250 ms to give windows time to redraw, before the crossfade.
You can set this delay like this:

```kdl
binds {
    Mod+Return { do-screen-transition delay-ms=100; }
}
```

Or, in scripts:

```shell
niri msg action do-screen-transition --delay-ms 100
```

#### `toggle-window-rule-opacity`

<sup>Since: 25.02</sup>

Toggle the opacity window rule of the focused window.
This only has an effect if the window's opacity window rule is already set to semitransparent.

```kdl
binds {
    Mod+O { toggle-window-rule-opacity; }
}
```

#### `screenshot`, `screenshot-screen`, `screenshot-window`

Actions for taking screenshots.

- `screenshot`: opens the built-in interactive screenshot UI.
- `screenshot-screen`, `screenshot-window`: takes a screenshot of the focused screen or window respectively.

The screenshot is both stored to the clipboard and saved to disk, according to the [`screenshot-path` option](https://niri-wm.github.io/niri/Configuration%3A-Miscellaneous.html#screenshot-path).

<sup>Since: 25.02</sup> You can disable saving to disk for a specific bind with the `write-to-disk=false` property:

```kdl
binds {
    Ctrl+Print { screenshot-screen write-to-disk=false; }
    Alt+Print { screenshot-window write-to-disk=false; }
}
```

In the interactive screenshot UI, pressing <kbd>Ctrl</kbd><kbd>C</kbd> will copy the screenshot to the clipboard without writing it to disk.

<sup>Since: 25.05</sup> You can hide the mouse pointer in screenshots with the `show-pointer=false` property:

```kdl
binds {
    // The pointer will be hidden by default
    // (you can still show it by pressing P).
    Print { screenshot show-pointer=false; }

    // The pointer will be hidden on the screenshot.
    Ctrl+Print { screenshot-screen show-pointer=false; }
}
```

<sup>Since: 26.04</sup> You can show the mouse pointer on window screenshots with the `show-pointer=true` property.
The pointer will be included only if the window is currently receiving pointer input (usually this means the pointer is on top of the window).

```kdl
binds {
    // The pointer will be visible on the screenshot
    // if it's on top of the window.
    Alt+Print { screenshot-window show-pointer=true; }
}
```

#### `toggle-keyboard-shortcuts-inhibit`

<sup>Since: 25.02</sup>

Applications such as remote-desktop clients and software KVM switches may request that niri stops processing its keyboard shortcuts so that they may, for example, forward the key presses as-is to a remote machine.
`toggle-keyboard-shortcuts-inhibit` is an escape hatch that toggles the inhibitor.
It's a good idea to bind it, so a buggy application can't hold your session hostage.

```kdl
binds {
    Mod+Escape { toggle-keyboard-shortcuts-inhibit; }
}
```

You can also make certain binds ignore inhibiting with the `allow-inhibiting=false` property.
They will always be handled by niri and never passed to the window.

```kdl
binds {
    // This bind will always work, even when using a virtual machine.
    Super+Alt+L allow-inhibiting=false { spawn "swaylock"; }
}
```



## Switch Events


### Overview

<sup>Since: 0.1.10</sup>

Switch event bindings are declared in the `switch-events {}` section of the config.

Here are all the events that you can bind at a glance:

```kdl
switch-events {
    lid-close { spawn "notify-send" "The laptop lid is closed!"; }
    lid-open { spawn "notify-send" "The laptop lid is open!"; }
    tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
    tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
}
```

The syntax is similar to key bindings.
Currently, only the [`spawn` action](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html#spawn) are supported.

> [!NOTE]
> In contrast to key bindings, switch event bindings are *always* executed, even when the session is locked.

### `lid-close`, `lid-open`

These events correspond to closing and opening of the laptop lid.

Note that niri will already automatically turn the internal laptop monitor on and off in accordance with the laptop lid.

```kdl
switch-events {
    lid-close { spawn "notify-send" "The laptop lid is closed!"; }
    lid-open { spawn "notify-send" "The laptop lid is open!"; }
}
```

### `tablet-mode-on`, `tablet-mode-off`

These events trigger when a convertible laptop goes into or out of tablet mode.
In tablet mode, the keyboard and mouse are usually inaccessible, so you can use these events to activate the on-screen keyboard.

> [!NOTE]
> The commands below are just examples, you will need to provide your own on-screen keyboard, such as [sysboard](https://github.com/System64fumo/sysboard) or [wvkbd](https://github.com/jjsullivan5196/wvkbd).

```kdl
switch-events {
    tablet-mode-on { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
    tablet-mode-off { spawn "bash" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
}
```



## Layout


### Overview

In the `layout {}` section you can change various settings that influence how windows are positioned and sized.

Here are the contents of this section at a glance:

```kdl
layout {
    gaps 16
    center-focused-column "never"
    always-center-single-column
    empty-workspace-above-first
    default-column-display "tabbed"
    background-color "#003300"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    default-column-width { proportion 0.5; }

    preset-window-heights {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    focus-ring {
        // off
        on
        width 4
        active-color "#7fc8ff"
        inactive-color "#505050"
        urgent-color "#9b0000"
        // active-gradient from="#80c8ff" to="#bbddff" angle=45
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        // urgent-gradient from="#800" to="#a33" angle=45
    }

    border {
        off
        // on
        width 4
        active-color "#ffc87f"
        inactive-color "#505050"
        urgent-color "#9b0000"
        // active-gradient from="#ffbb66" to="#ffc880" angle=45 relative-to="workspace-view"
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view" in="srgb-linear"
        // urgent-gradient from="#800" to="#a33" angle=45
    }

    shadow {
        off
        // on
        softness 30
        spread 5
        offset x=0 y=5
        draw-behind-window true
        color "#00000070"
        // inactive-color "#00000054"
    }

    tab-indicator {
        // off
        on
        hide-when-single-tab
        place-within-column
        gap 5
        width 4
        length total-proportion=1.0
        position "right"
        gaps-between-tabs 2
        corner-radius 8
        active-color "red"
        inactive-color "gray"
        urgent-color "blue"
        // active-gradient from="#80c8ff" to="#bbddff" angle=45
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        // urgent-gradient from="#800" to="#a33" angle=45
    }

    insert-hint {
        // off
        on
        color "#ffc87f80"
        // gradient from="#ffbb6680" to="#ffc88080" angle=45 relative-to="workspace-view"
    }

    struts {
        // left 64
        // right 64
        // top 64
        // bottom 64
    }
}
```

<sup>Since: 25.11</sup> You can override these settings for specific [outputs](https://niri-wm.github.io/niri/Configuration%3A-Outputs.html#layout-config-overrides) and [named workspaces](https://niri-wm.github.io/niri/Configuration%3A-Named-Workspaces.html#layout-config-overrides).

### `gaps`

Set gaps around (inside and outside) windows in logical pixels.

<sup>Since: 0.1.7</sup> You can use fractional values.
The value will be rounded to physical pixels according to the scale factor of every output.
For example, `gaps 0.5` on an output with `scale 2` will result in one physical-pixel wide gaps.

<sup>Since: 0.1.8</sup> You can emulate "inner" vs. "outer" gaps with negative `struts` values (see the struts section below).

```kdl
layout {
    gaps 16
}
```

### `center-focused-column`

When to center a column when changing focus.
This can be set to:

- `"never"`: no special centering, focusing an off-screen column will scroll it to the left or right edge of the screen. This is the default.
- `"always"`, the focused column will always be centered.
- `"on-overflow"`, focusing a column will center it if it doesn't fit on screen together with the previously focused column.

```kdl
layout {
    center-focused-column "always"
}
```

### `always-center-single-column`

<sup>Since: 0.1.9</sup>

If set, niri will always center a single column on a workspace, regardless of the `center-focused-column` option.

```kdl
layout {
    always-center-single-column
}
```

### `empty-workspace-above-first`

<sup>Since: 25.01</sup>

If set, niri will always add an empty workspace at the very start, in addition to the empty workspace at the very end.

```kdl
layout {
    empty-workspace-above-first
}
```

### `default-column-display`

<sup>Since: 25.02</sup>

Sets the default display mode for new columns.
Can be `normal` or `tabbed`.

```kdl
// Make all new columns tabbed by default.
layout {
    default-column-display "tabbed"

    // You may also want to hide the tab indicator
    // when there's only a single window in a column.
    tab-indicator {
        hide-when-single-tab
    }
}
```

### `preset-column-widths`

Set the widths that the `switch-preset-column-width` action (Mod+R) toggles between.
<sup>Since: 25.08</sup> You can use the `switch-preset-column-width-back` action (Mod+Shift+R) to toggle in reverse.

`proportion` sets the width as a fraction of the output width, taking gaps into account.
For example, you can perfectly fit four windows sized `proportion 0.25` on an output, regardless of the gaps setting.
The default preset widths are <sup>1</sup>&frasl;<sub>3</sub>, <sup>1</sup>&frasl;<sub>2</sub> and <sup>2</sup>&frasl;<sub>3</sub> of the output.

`fixed` sets the window width in logical pixels exactly.

```kdl
layout {
    // Cycle between 1/3, 1/2, 2/3 of the output, and a fixed 1280 logical pixels.
    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
        fixed 1280
    }
}
```

### `default-column-width`

Set the default width of the new windows.

The syntax is the same as in `preset-column-widths` above.

```kdl
layout {
    // Open new windows sized 1/3 of the output.
    default-column-width { proportion 0.33333; }
}
```

You can also leave the brackets empty, then the windows themselves will decide their initial width.

```kdl
layout {
    // New windows decide their initial width themselves.
    default-column-width {}
}
```

> [!NOTE]
> `default-column-width {}` causes niri to send a (0, H) size in the initial configure request.
>
> This is a bit [unclearly defined](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/issues/155) in the Wayland protocol, so some clients may misinterpret it.
> Either way, `default-column-width {}` is most useful for specific windows, in form of a [window rule](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#default-column-width) with the same syntax.

### `preset-window-heights`

<sup>Since: 0.1.9</sup>

Set the heights that the `switch-preset-window-height` action (Mod+Ctrl+Shift+R) toggles between.
<sup>Since: 25.08</sup> You can use the `switch-preset-window-height-back` action (not bound by default) to toggle in reverse.

`proportion` sets the height as a fraction of the output height, taking gaps into account.
The default preset heights are <sup>1</sup>&frasl;<sub>3</sub>, <sup>1</sup>&frasl;<sub>2</sub> and <sup>2</sup>&frasl;<sub>3</sub> of the output.

`fixed` sets the height in logical pixels exactly.

```kdl
layout {
    // Cycle between 1/3, 1/2, 2/3 of the output, and a fixed 720 logical pixels.
    preset-window-heights {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
        fixed 720
    }
}
```

### `focus-ring` and `border`

Focus ring and border are drawn around windows and indicate the active window.
They are very similar and have the same options.

The difference is that the focus ring is drawn only around the active window, whereas borders are drawn around all windows and affect their sizes (windows shrink to make space for the borders).

| Focus Ring                | Border                |
| ------------------------- | --------------------- |
| ![Screenshot showing a focused image in the center row using focus ring](https://niri-wm.github.io/niri/img%2Ffocus-ring.png) | ![Screenshot showing a focused image in the center row using border, while top and bottom windows have the inactive color](https://niri-wm.github.io/niri/img%2Fborder.png) |

> [!TIP]
> By default, focus ring and border are rendered as a solid background rectangle behind windows.
> That is, they will show up through semitransparent windows.
> This is because windows using client-side decorations can have an arbitrary shape.
>
> If you don't like that, you should uncomment the [`prefer-no-csd` setting](https://niri-wm.github.io/niri/Configuration%3A-Miscellaneous.html#prefer-no-csd) at the top level of the config.
> Niri will draw focus rings and borders *around* windows that agree to omit their client-side decorations.
>
> Alternatively, you can override this behavior with the [`draw-border-with-background` window rule](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#draw-border-with-background).

Focus ring and border have the following options.

```kdl
layout {
    // focus-ring has the same options.
    border {
        // Uncomment this line to disable the border.
        // off

        // Width of the border in logical pixels.
        width 4

        active-color "#ffc87f"
        inactive-color "#505050"

        // Color of the border around windows that request your attention.
        urgent-color "#9b0000"

        // active-gradient from="#ffbb66" to="#ffc880" angle=45 relative-to="workspace-view"
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view" in="srgb-linear"
    }
}
```

#### Width

Set the thickness of the border in logical pixels.

<sup>Since: 0.1.7</sup> You can use fractional values.
The value will be rounded to physical pixels according to the scale factor of every output.
For example, `width 0.5` on an output with `scale 2` will result in one physical-pixel thick borders.

```kdl
layout {
    border {
        width 2
    }
}
```

#### Colors

Colors can be set in a variety of ways:

- CSS named colors: `"red"`
- RGB hex: `"#rgb"`, `"#rgba"`, `"#rrggbb"`, `"#rrggbbaa"`
- CSS-like notation: `"rgb(255, 127, 0)"`, `"rgba()"`, `"hsl()"` and a few others.

`active-color` is the color of the focus ring / border around the active window, and `inactive-color` is the color of the focus ring / border around all other windows.

The *focus ring* is only drawn around the active window on each monitor, so with a single monitor you will never see its `inactive-color`.
You will see it if you have multiple monitors, though.

There's also a *deprecated* syntax for setting colors with four numbers representing R, G, B and A: `active-color 127 200 255 255`.

#### Gradients

Similarly to colors, you can set `active-gradient` and `inactive-gradient`, which will take precedence.

Gradients are rendered the same as CSS [`linear-gradient(angle, from, to)`](https://developer.mozilla.org/en-US/docs/Web/CSS/gradient/linear-gradient).
The angle works the same as in `linear-gradient`, and is optional, defaulting to `180` (top-to-bottom gradient).
You can use any CSS linear-gradient tool on the web to set these up, like [css-gradient.com](https://www.css-gradient.com/).

```kdl
layout {
    focus-ring {
        active-gradient from="#80c8ff" to="#bbddff" angle=45
    }
}
```

Gradients can be colored relative to windows individually (the default), or to the whole view of the workspace.
To do that, set `relative-to="workspace-view"`.
Here's a visual example:

| Default                          | `relative-to="workspace-view"`                      |
| -------------------------------- | --------------------------------------------------- |
| ![Screenshot displaying 4 windows, each with individual gradient borders](https://niri-wm.github.io/niri/img%2Fgradients-default.png) | ![Screenshot displaying 4 windows, with a shared gradient across their borders](https://niri-wm.github.io/niri/img%2Fgradients-relative-to-workspace-view.png) |

```kdl
layout {
    border {
        active-gradient from="#ffbb66" to="#ffc880" angle=45 relative-to="workspace-view"
        inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
    }
}
```

<sup>Since: 0.1.8</sup> You can set the gradient interpolation color space using syntax like `in="srgb-linear"` or `in="oklch longer hue"`.
Supported color spaces are:

- `srgb` (the default),
- `srgb-linear`,
- `oklab`,
- `oklch` with `shorter hue` or `longer hue` or `increasing hue` or `decreasing hue`.

They are rendered the same as CSS.
For example, `active-gradient from="#f00f" to="#0f05" angle=45 in="oklch longer hue"` will look the same as CSS `linear-gradient(45deg in oklch longer hue, #f00f, #0f05)`.

![Screenshot showing a window with a border using a gradient in the oklch color space](https://niri-wm.github.io/niri/img%2Fgradients-oklch.png)

```kdl
layout {
    border {
        active-gradient from="#f00f" to="#0f05" angle=45 in="oklch longer hue"
    }
}
```

### `shadow`

<sup>Since: 25.02</sup>

Shadow rendered behind a window.

Set `on` to enable the shadow.

`softness` controls the shadow softness/size in logical pixels, same as [CSS box-shadow] *blur radius*.
Setting `softness 0` will give you hard shadows.

`spread` is the distance to expand the window rectangle in logical pixels, same as CSS box-shadow spread.
<sup>Since: 25.05</sup> Spread can be negative.

`offset` moves the shadow relative to the window in logical pixels, same as CSS box-shadow offset.
For example, `offset x=2 y=2` will move the shadow 2 logical pixels downwards and to the right.

Set `draw-behind-window` to `true` to make shadows draw behind the window rather than just around it.
Note that niri has no way of knowing about the CSD window corner radius.
It has to assume that windows have square corners, leading to shadow artifacts inside the CSD rounded corners.
This setting fixes those artifacts.

However, instead you may want to set `prefer-no-csd` and/or `geometry-corner-radius`.
Then, niri will know the corner radius and draw the shadow correctly, without having to draw it behind the window.
These will also remove client-side shadows if the window draws any.

`color` is the shadow color and opacity.

`inactive-color` lets you override the shadow color for inactive windows; by default, a more transparent `color` is used.

Shadow drawing will follow the window corner radius set with the [`geometry-corner-radius` window rule](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#geometry-corner-radius).

> [!NOTE]
> Currently, shadow drawing only supports matching radius for all corners. If you set `geometry-corner-radius` to four values instead of one, the first (top-left) corner radius will be used for shadows.

```kdl
// Enable shadows.
layout {
    shadow {
        on
    }
}

// Also ask windows to omit client-side decorations, so that
// they don't draw their own window shadows.
prefer-no-csd
```

[CSS box-shadow]: https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow

### `tab-indicator`

<sup>Since: 25.02</sup>

Controls the appearance of the tab indicator that appears next to columns in tabbed display mode.

Set `off` to hide the tab indicator.

Set `hide-when-single-tab` to hide the indicator for tabbed columns that only have a single window.

Set `place-within-column` to put the tab indicator "within" the column, rather than outside.
This will include it in column sizing and avoid overlaying adjacent columns.

`gap` sets the gap between the tab indicator and the window in logical pixels.
The gap can be negative, this will put the tab indicator on top of the window.

`width` sets the thickness of the indicator in logical pixels.

`length` controls the length of the indicator.
Set the `total-proportion` property to make tabs take up this much length relative to the window size.
By default, the tab indicator has length equal to half of the window size, or `length total-proportion=0.5`.

`position` sets the position of the tab indicator relative to the window.
It can be `left`, `right`, `top`, or `bottom`.

`gaps-between-tabs` controls the gap between individual tabs in logical pixels.

`corner-radius` sets the rounded corner radius for tabs in the indicator in logical pixels.
When `gaps-between-tabs` is zero, only the first and the last tabs have rounded corners, otherwise all tabs do.

`active-color`, `inactive-color`, `urgent-color`, `active-gradient`, `inactive-gradient`, `urgent-gradient` let you override the colors for the tabs.
They have the same semantics as the border and focus ring colors and gradients.

Tab colors are picked in this order:

1. Colors from the `tab-indicator` window rule, if set.
1. Colors from the `tab-indicator` layout options, if set (you're here).
1. If neither are set, niri picks the color matching the window border or focus ring, whichever one is active.

```kdl
// Make the tab indicator wider and match the window height,
// also put it at the top and within the column.
layout {
    tab-indicator {
        width 8
        gap 8
        length total-proportion=1.0
        position "top"
        place-within-column
    }
}
```

### `insert-hint`

<sup>Since: 0.1.10</sup> 

Settings for the window insert position hint during an interactive window move.

`off` disables the insert hint altogether.

`color` and `gradient` let you change the color of the hint and have the same syntax as colors and gradients in border and focus ring.

```kdl
layout {
    insert-hint {
        // off
        color "#ffc87f80"
        gradient from="#ffbb6680" to="#ffc88080" angle=45 relative-to="workspace-view"
    }
}
```

### `struts`

Struts shrink the area occupied by windows, similarly to layer-shell panels.
You can think of them as a kind of outer gaps.
They are set in logical pixels.

Left and right struts will cause the next window to the side to always peek out slightly.
Top and bottom struts will simply add outer gaps in addition to the area occupied by layer-shell panels and regular gaps.

<sup>Since: 0.1.7</sup> You can use fractional values.
The value will be rounded to physical pixels according to the scale factor of every output.
For example, `top 0.5` on an output with `scale 2` will result in one physical-pixel wide top strut.

```kdl
layout {
    struts {
        left 64
        right 64
        top 64
        bottom 64
    }
}
```

![A screenshot illustrating the effects of struts, as explained in the second paragraph in this section](https://niri-wm.github.io/niri/img%2Fstruts.png)

<sup>Since: 0.1.8</sup> You can use negative values.
They will push the windows outwards, even outside the edges of the screen.

You can use negative struts with matching gaps value to emulate "inner" vs. "outer" gaps.
For example, use this for inner gaps without outer gaps:

```kdl
layout {
    gaps 16

    struts {
        left -16
        right -16
        top -16
        bottom -16
    }
}
```

### `background-color`

<sup>Since: 25.05</sup>

Set the default background color that niri draws for workspaces.
This is visible when you're not using any background tools like swaybg.

```kdl
layout {
    background-color "#003300"
}
```

You can also set the color per-output [in the output config](https://niri-wm.github.io/niri/Configuration%3A-Outputs.html#layout-config-overrides).



## Named Workspaces


### Overview

<sup>Since: 0.1.6</sup>

You can declare named workspaces at the top level of the config:

```kdl
workspace "browser"

workspace "chat" {
    open-on-output "Some Company CoolMonitor 1234"
}
```

Contrary to normal dynamic workspaces, named workspaces always exist, even when they have no windows.
Otherwise, they behave like any other workspace: you can move them around, move to a different monitor, and so on.

Actions like `focus-workspace` or `move-column-to-workspace` can refer to workspaces by name.
Also, you can use an `open-on-workspace` window rule to make a window open on a specific named workspace:

```kdl
// Declare a workspace named "chat" that opens on the "DP-2" output.
workspace "chat" {
    open-on-output "DP-2"
}

// Open Fractal on the "chat" workspace, if it runs at niri startup.
window-rule {
    match at-startup=true app-id=r#"^org\.gnome\.Fractal$"#
    open-on-workspace "chat"
}
```

Named workspaces initially appear in the order they are declared in the config file.
When editing the config while niri is running, newly declared named workspaces will appear at the very top of a monitor.

If you delete some named workspace from the config, the workspace will become normal (unnamed), and if there are no windows on it, it will be removed (as any other normal workspace).
There's no way to give a name to an already existing workspace, but you can simply move windows that you want to a new, empty named workspace.

<sup>Since: 0.1.9</sup> `open-on-output` can now use monitor manufacturer, model, and serial.
Before, it could only use the connector name.

<sup>Since: 25.01</sup> You can use `set-workspace-name` and `unset-workspace-name` actions to change workspace names dynamically.

<sup>Since: 25.02</sup> Named workspaces no longer update/forget their original output when opening a new window on them (unnamed workspaces will keep doing that).
This means that named workspaces "stick" to their original output in more cases, reflecting their more permanent nature.
Explicitly moving a named workspace to a different monitor will still update its original output.

### Layout config overrides

<sup>Since: 25.11</sup>

You can customize layout settings for named workspaces with a `layout {}` block:

```kdl
workspace "aesthetic" {
    // Layout config overrides just for this named workspace.
    layout {
        gaps 32

        struts {
            left 64
            right 64
            bottom 64
            top 64
        }

        border {
            on
            width 4
        }

        // ...any other setting.
    }
}
```

It accepts all the same options as [the top-level `layout {}` block](https://niri-wm.github.io/niri/Configuration%3A-Layout.html), except:

- `empty-workspace-above-first`: this is an output-level setting, doesn't make sense on a workspace.
- `insert-hint`: currently we always draw these at the output level, so it's not customizable per-workspace.

In order to unset a flag, write it with `false`, e.g.:

```kdl
layout {
    // Enabled globally.
    always-center-single-column
}

workspace "uncentered" {
    layout {
        // Unset on this workspace.
        always-center-single-column false
    }
}
```



## Miscellaneous


This page documents all top-level options that don't otherwise have dedicated pages.

Here are all of these options at a glance:

```kdl
spawn-at-startup "waybar"
spawn-at-startup "alacritty"
spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"

prefer-no-csd

screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

environment {
    QT_QPA_PLATFORM "wayland"
    DISPLAY null
}

cursor {
    xcursor-theme "breeze_cursors"
    xcursor-size 48

    hide-when-typing
    hide-after-inactive-ms 1000
}

overview {
    zoom 0.5
    backdrop-color "#262626"

    workspace-shadow {
        // off
        softness 40
        spread 10
        offset x=0 y=10
        color "#00000050"
    }
}

xwayland-satellite {
    // off
    path "xwayland-satellite"
}

clipboard {
    disable-primary
}

hotkey-overlay {
    skip-at-startup
    hide-not-bound
}

config-notification {
    disable-failed
}

blur {
    // off
    passes 3
    offset 3.0
    noise 0.02
    saturation 1.5
}
```

### `spawn-at-startup`

Add lines like this to spawn processes at niri startup.

`spawn-at-startup` accepts a path to the program binary as the first argument, followed by arguments to the program.

This option works the same way as the [`spawn` key binding action](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html#spawn), so please read about all its subtleties there.

```kdl
spawn-at-startup "waybar"
spawn-at-startup "alacritty"
```

Note that running niri as a systemd session supports xdg-desktop-autostart out of the box, which may be more convenient to use.
Thanks to this, apps that you configured to autostart in GNOME will also "just work" in niri, without any manual `spawn-at-startup` configuration.

### `spawn-sh-at-startup`

<sup>Since: 25.08</sup>

Add lines like this to run shell commands at niri startup.

The argument is a single string that is passed verbatim to `sh`.
You can use shell variables, pipelines, `~` expansion and everything else as expected.

See detailed description in the docs for the [`spawn-sh` key binding action](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html#spawn-sh).

```kdl
// Pass all arguments in the same string.
spawn-sh-at-startup "qs -c ~/source/qs/MyAwesomeShell"
```

### `prefer-no-csd`

This flag will make niri ask the applications to omit their client-side decorations.

If an application will specifically ask for CSD, the request will be honored.
Additionally, clients will be informed that they are tiled, removing some rounded corners.

With `prefer-no-csd` set, applications that negotiate server-side decorations through the xdg-decoration protocol will have focus ring and border drawn around them *without* a solid colored background.

> [!NOTE]
> Unlike most other options, changing `prefer-no-csd` will not entirely affect already running applications.
> It will make some windows rectangular, but won't remove the title bars.
> This mainly has to do with niri working around a [bug in SDL2](https://github.com/libsdl-org/SDL/issues/8173) that prevents SDL2 applications from starting.
>
> Restart applications after changing `prefer-no-csd` in the config to fully apply it.

```kdl
prefer-no-csd
```

### `screenshot-path`

Set the path where screenshots are saved.
A `~` at the front will be expanded to the home directory.

The path is formatted with `strftime(3)` to give you the screenshot date and time.

Niri will create the last folder of the path if it doesn't exist.

```kdl
screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
```

You can also set this option to `null` to disable saving screenshots to disk.

```kdl
screenshot-path null
```

### `environment`

Override environment variables for processes spawned by niri.

```kdl
environment {
    // Set a variable like this:
    // QT_QPA_PLATFORM "wayland"

    // Remove a variable by using null as the value:
    // DISPLAY null
}
```

Note that these variables do not propagate to the systemd global environment, so tools and applications started by systemd do not see them.
In particular, if you start a desktop shell like DankMaterialShell through systemd, then use its built-in application launcher, the apps won't see these environment variables.

If you want all processes to see the environment variables, you can set them in your login shell config instead (i.e. `~/.bash_profile`).
The `niri-session` shell script runs through the login shell and imports all environment variables to systemd before starting niri.
Keep in mind that all compositors will see variables set in the login shell, not just niri.

### `cursor`

Change the theme and size of the cursor as well as set the `XCURSOR_THEME` and `XCURSOR_SIZE` environment variables.

```kdl
cursor {
    xcursor-theme "breeze_cursors"
    xcursor-size 48
}
```

#### `hide-when-typing`

<sup>Since: 0.1.10</sup>

If set, hides the cursor when pressing a key on the keyboard.

> [!NOTE]
> This setting might interfere with games running in Wine in native Wayland mode that use mouselook, such as first-person games.
> If your character's point of view jumps down when you press a key and move the mouse simultaneously, try disabling this setting.

```kdl
cursor {
    hide-when-typing
}
```

#### `hide-after-inactive-ms`

<sup>Since: 0.1.10</sup>

If set, the cursor will automatically hide once this number of milliseconds passes since the last cursor movement.

```kdl
cursor {
    // Hide the cursor after one second of inactivity.
    hide-after-inactive-ms 1000
}
```

### `overview`

<sup>Since: 25.05</sup>

Settings for the [Overview](https://niri-wm.github.io/niri/Overview.html).

#### `zoom`

Control how much the workspaces zoom out in the overview.
`zoom` ranges from 0 to 0.75 where lower values make everything smaller.

```kdl
// Make workspaces four times smaller than normal in the overview.
overview {
    zoom 0.25
}
```

#### `backdrop-color`

Set the backdrop color behind workspaces in the overview.
The backdrop is also visible between workspaces when switching.

The alpha channel for this color will be ignored.

```kdl
// Make the backdrop light.
overview {
    backdrop-color "#777777"
}
```

You can also set the color per-output [in the output config](https://niri-wm.github.io/niri/Configuration%3A-Outputs.html#backdrop-color).

#### `workspace-shadow`

Control the shadow behind workspaces visible in the overview.

Settings here mirror the normal [`shadow` config in the layout section](https://niri-wm.github.io/niri/Configuration%3A-Layout.html#shadow), so check the documentation there.

Workspace shadows are configured for a workspace size normalized to 1080 pixels tall, then zoomed out together with the workspace.
Practically, this means that you'll want bigger spread, offset, and softness compared to window shadows.

```kdl
// Disable workspace shadows in the overview.
overview {
    workspace-shadow {
        off
    }
}
```

### `xwayland-satellite`

<sup>Since: 25.08</sup>

Settings for integration with [xwayland-satellite](https://github.com/Supreeeme/xwayland-satellite).

When a recent enough xwayland-satellite is detected, niri will create the X11 sockets and set `DISPLAY`, then automatically spawn `xwayland-satellite` when an X11 client tries to connect.
If Xwayland dies, niri will keep watching the X11 socket and restart `xwayland-satellite` as needed.
This is very similar to how built-in Xwayland works in other compositors.

`off` disables the integration: niri won't create an X11 socket and won't set the `DISPLAY` environment variable.

`path` sets the path to the `xwayland-satellite` binary.
By default, it's just `xwayland-satellite`, so it's looked up like any other non-absolute program name.

```kdl
// Use a custom build of xwayland-satellite.
xwayland-satellite {
    path "~/source/rs/xwayland-satellite/target/release/xwayland-satellite"
}
```

### `clipboard`

<sup>Since: 25.02</sup>

Clipboard settings.

Set the `disable-primary` flag to disable the primary clipboard (middle-click paste).
Toggling this flag will only apply to applications started afterward.

```kdl
clipboard {
    disable-primary
}
```

### `hotkey-overlay`

Settings for the "Important Hotkeys" overlay.

#### `skip-at-startup`

Set the `skip-at-startup` flag if you don't want to see the hotkey help at niri startup.

```kdl
hotkey-overlay {
    skip-at-startup
}
```

#### `hide-not-bound`

<sup>Since: 25.08</sup>

By default, niri will show the most important actions even if they aren't bound to any key, to prevent confusion.
Set the `hide-not-bound` flag if you want to hide all actions not bound to any key.

```kdl
hotkey-overlay {
    hide-not-bound
}
```

You can customize which binds the hotkey overlay shows using the [`hotkey-overlay-title` property](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html#custom-hotkey-overlay-titles).

### `config-notification`

<sup>Since: 25.08</sup>

Settings for the config created/failed notification.

Set the `disable-failed` flag to disable the "Failed to parse the config file" notification.
For example, if you have a custom one.

```kdl
config-notification {
    disable-failed
}
```

### `blur`

<sup>Since: 26.04</sup>

Blur configuration that affects all background blur.

See the [window effects page](https://niri-wm.github.io/niri/Window-Effects.html) for an overview of background effects.

```kdl
// These are the default values:
blur {
    // off
    passes 3
    offset 3
    noise 0.02
    saturation 1.5
}
```

#### `off`

By default, blur is available on request by a window or layer surface (via the `ext-background-effect` protocol).
You can also enable it manually with the `blur true` background effect [window](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#background-effect) or [layer](https://niri-wm.github.io/niri/Configuration%3A-Layer-Rules.html#background-effect) rule.

Setting the `off` flag will disable all blur, both requested by the window, and configured in window rules.

```kdl
blur {
    off
}
```

#### `passes` and `offset`

`passes` controls the number of downsample/upsample passes for dual kawase blur.
More passes produce a larger, smoother blur, but cost more GPU resources.

`offset` is the pixel offset multiplier for each pass.
Offset `1` is the original dual kawase blur.
Larger values produce a smoother blur, at no additional GPU cost.

However, setting `offset` too big will produce visual artifacts.
You will need to increase `passes` to be able to use a bigger `offset` without artifacts.

When configuring blur, try increasing `offset` first (since it doesn't cause any extra GPU load) until you start getting artifacts.
Then, if you still need smoother blur, increase `passes` by 1.
Keep doing this until you get the desired visuals. 

```kdl
blur {
    passes 3
    offset 3.0
}
```

#### `noise`

Amount of noise to add on top of the blur.

This is helpful to reduce color banding artifacts.

```kdl
blur {
    noise 0.02
}
```

#### `saturation`

Color saturation applied to the blurred background.

Values above `1` increase saturation; values below `1` reduce it.

```kdl
blur {
    saturation 1.5
}
```



## Window Rules


### Overview

Window rules let you adjust behavior for individual windows.
They have `match` and `exclude` directives that control which windows the rule should apply to, and a number of properties that you can set.

Window rules are processed in order of appearance in the config file.
This means that you can put more generic rules first, then override them for specific windows later.
For example:

```kdl
// Set open-maximized to true for all windows.
window-rule {
    open-maximized true
}

// Then, for Alacritty, set open-maximized back to false.
window-rule {
    match app-id="Alacritty"
    open-maximized false
}
```

> [!TIP]
> In general, you cannot "unset" a property in a later rule, only set it to a different value.
> Use the `exclude` directives to avoid applying a rule for specific windows.

Here are all matchers and properties that a window rule could have:

```kdl
window-rule {
    match title="Firefox"
    match app-id="Alacritty"
    match is-active=true
    match is-focused=false
    match is-active-in-column=true
    match is-floating=true
    match is-window-cast-target=true
    match is-urgent=true
    match at-startup=true

    // Properties that apply once upon window opening.
    default-column-width { proportion 0.75; }
    default-window-height { fixed 500; }
    open-on-output "Some Company CoolMonitor 1234"
    open-on-workspace "chat"
    open-maximized true
    open-maximized-to-edges true
    open-fullscreen true
    open-floating true
    open-focused false

    // Properties that apply continuously.
    draw-border-with-background false
    opacity 0.5
    block-out-from "screencast"
    // block-out-from "screen-capture"
    variable-refresh-rate true
    default-column-display "tabbed"
    default-floating-position x=100 y=200 relative-to="bottom-left"
    scroll-factor 0.75

    focus-ring {
        // off
        on
        width 4
        active-color "#7fc8ff"
        inactive-color "#505050"
        urgent-color "#9b0000"
        // active-gradient from="#80c8ff" to="#bbddff" angle=45
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        // urgent-gradient from="#800" to="#a33" angle=45
    }

    border {
        // Same as focus-ring.
    }

    shadow {
        // on
        off
        softness 40
        spread 5
        offset x=0 y=5
        draw-behind-window true
        color "#00000064"
        // inactive-color "#00000064"
    }

    tab-indicator {
        active-color "red"
        inactive-color "gray"
        urgent-color "blue"
        // active-gradient from="#80c8ff" to="#bbddff" angle=45
        // inactive-gradient from="#505050" to="#808080" angle=45 relative-to="workspace-view"
        // urgent-gradient from="#800" to="#a33" angle=45
    }

    geometry-corner-radius 12
    clip-to-geometry true
    tiled-state true
    baba-is-float true

    background-effect {
        xray true
        blur true
        noise 0.05
        saturation 3
    }

    popups {
        opacity 0.5
        geometry-corner-radius 15

        background-effect {
            xray true
            blur true
            noise 0.05
            saturation 3
        }
    }

    min-width 100
    max-width 200
    min-height 300
    max-height 300
}
```

### Window Matching

Each window rule can have several `match` and `exclude` directives.
In order for the rule to apply, a window needs to match *any* of the `match` directives, and *none* of the `exclude` directives.

```kdl
window-rule {
    // Match all Telegram windows...
    match app-id=r#"^org\.telegram\.desktop$"#

    // ...except the media viewer window.
    exclude title="^Media viewer$"

    // Properties to apply.
    open-on-output "HDMI-A-1"
}
```

Match and exclude directives have the same syntax.
There can be multiple *matchers* in one directive, then the window should match all of them for the directive to apply.

```kdl
window-rule {
    // Match Firefox windows with Gmail in title.
    match app-id="firefox" title="Gmail"
}

window-rule {
    // Match Firefox, but only when it is active...
    match app-id="firefox" is-active=true

    // ...or match Telegram...
    match app-id=r#"^org\.telegram\.desktop$"#

    // ...but don't match the Telegram media viewer.
    // If you open a tab in Firefox titled "Media viewer",
    // it will not be excluded because it doesn't match the app-id
    // of this exclude directive.
    exclude app-id=r#"^org\.telegram\.desktop$"# title="Media viewer"
}
```

Let's look at the matchers in more detail.

#### `title` and `app-id`

These are regular expressions that should match anywhere in the window title and app ID respectively.
You can read about the supported regular expression syntax [here](https://docs.rs/regex/latest/regex/#syntax).

```kdl
// Match windows with title containing "Mozilla Firefox",
// or windows with app ID containing "Alacritty".
window-rule {
    match title="Mozilla Firefox"
    match app-id="Alacritty"
}
```

Raw KDL strings can be helpful for writing out regular expressions:

```kdl
window-rule {
    exclude app-id=r#"^org\.keepassxc\.KeePassXC$"#
}
```

You can find the title and the app ID of a window by running `niri msg pick-window` and clicking on the window in question.

> [!TIP]
> Another way to find the window title and app ID is to configure the `wlr/taskbar` module in [Waybar](https://github.com/Alexays/Waybar) to include them in the tooltip:
> 
> ```json
> "wlr/taskbar": {
>     "tooltip-format": "{title} | {app_id}",
> }
> ```

#### `is-active`

Can be `true` or `false`.
Matches active windows (same windows that have the active border / focus ring color).

Every workspace on the focused monitor will have one active window.
This means that you will usually have multiple active windows (one per workspace), and when you switch between workspaces, you can see two active windows at once.

```kdl
window-rule {
    match is-active=true
}
```

#### `is-focused`

Can be `true` or `false`.
Matches the window that has the keyboard focus.

Contrary to `is-active`, there can only be a single focused window.
Also, when opening a layer-shell application launcher or pop-up menu, the keyboard focus goes to layer-shell.
While layer-shell has the keyboard focus, windows will not match this rule.

```kdl
window-rule {
    match is-focused=true
}
```

#### `is-active-in-column`

<sup>Since: 0.1.6</sup>

Can be `true` or `false`.
Matches the window that is the "active" window in its column.

Contrary to `is-active`, there is always one `is-active-in-column` window in each column.
It is the window that was last focused in the column, i.e. the one that will gain focus if this column is focused.

<sup>Since: 25.01</sup> This rule will match `true` during the initial window opening.

```kdl
window-rule {
    match is-active-in-column=true
}
```

#### `is-floating`

<sup>Since: 25.01</sup>

Can be `true` or `false`.
Matches floating windows.

> [!NOTE]
> This matcher will apply only after the window is already open.
> This means that you cannot use it to change the window opening properties like `default-window-height` or `open-on-workspace`.

```kdl
window-rule {
    match is-floating=true
}
```

#### `is-window-cast-target`

<sup>Since: 25.02</sup>

Can be `true` or `false`.
Matches `true` for windows that are target of an ongoing window screencast.

> [!NOTE]
> This only matches individual-window screencasts.
> It will not match windows that happen to be visible in a monitor screencast, for example.

```kdl
// Indicate screencasted windows with red colors.
window-rule {
    match is-window-cast-target=true

    focus-ring {
        active-color "#f38ba8"
        inactive-color "#7d0d2d"
    }

    border {
        inactive-color "#7d0d2d"
    }

    shadow {
        color "#7d0d2d70"
    }

    tab-indicator {
        active-color "#f38ba8"
        inactive-color "#7d0d2d"
    }
}
```

Example:

![A screenshot showing that only the is-window-cast-target=true windows receive the special border colors](https://github.com/user-attachments/assets/375b381e-3a87-4e94-8676-44404971d893)

#### `is-urgent`

<sup>Since: 25.05</sup>

Can be `true` or `false`.
Matches windows that request the user's attention.

```kdl
window-rule {
    match is-urgent=true
}
```

#### `at-startup`

<sup>Since: 0.1.6</sup>

Can be `true` or `false`.
Matches during the first 60 seconds after starting niri.

This is useful for properties like `open-on-output` which you may want to apply only right after starting niri.

```kdl
// Open windows on the HDMI-A-1 monitor at niri startup, but not afterwards.
window-rule {
    match at-startup=true
    open-on-output "HDMI-A-1"
}
```

### Window Opening Properties

These properties apply once, when a window first opens.

To be precise, they apply at the point when niri sends the initial configure request to the window.

#### `default-column-width`

Set the default width for the new window.

This works for floating windows too, despite the word "column" in the name.

```kdl
// Give Blender and GIMP some guaranteed width on opening.
window-rule {
    match app-id="^blender$"

    // GIMP app ID contains the version like "gimp-2.99",
    // so we only match the beginning (with ^) and not the end.
    match app-id="^gimp"

    default-column-width { fixed 1200; }
}
```

#### `default-window-height`

<sup>Since: 25.01</sup>

Set the default height for the new window.

```kdl
// Open the Firefox picture-in-picture window as floating with 480×270 size.
window-rule {
    match app-id="firefox$" title="^Picture-in-Picture$"

    open-floating true
    default-column-width { fixed 480; }
    default-window-height { fixed 270; }
}
```

#### `open-on-output`

Make the window open on a specific output.

If such an output does not exist, the window will open on the currently focused output as usual.

If the window opens on an output that is not currently focused, the window will not be automatically focused.

```kdl
// Open Firefox and Telegram (but not its Media Viewer)
// on a specific monitor.
window-rule {
    match app-id="firefox$"
    match app-id=r#"^org\.telegram\.desktop$"#
    exclude app-id=r#"^org\.telegram\.desktop$"# title="^Media viewer$"

    open-on-output "HDMI-A-1"
    // Or:
    // open-on-output "Some Company CoolMonitor 1234"
}
```

<sup>Since: 0.1.9</sup> `open-on-output` can now use monitor manufacturer, model, and serial.
Before, it could only use the connector name.

#### `open-on-workspace`

<sup>Since: 0.1.6</sup>

Make the window open on a specific [named workspace](https://niri-wm.github.io/niri/Configuration%3A-Named-Workspaces.html).

If such a workspace does not exist, the window will open on the currently focused workspace as usual.

If the window opens on an output that is not currently focused, the window will not be automatically focused.

```kdl
// Open Fractal on the "chat" workspace.
window-rule {
    match app-id=r#"^org\.gnome\.Fractal$"#

    open-on-workspace "chat"
}
```

#### `open-maximized`

Make the window open as a maximized column.

```kdl
// Maximize Firefox by default.
window-rule {
    match app-id="firefox$"

    open-maximized true
}
```

#### `open-maximized-to-edges`

<sup>Since: 25.11</sup>

Make the window open [maximized to edges](https://niri-wm.github.io/niri/Fullscreen-and-Maximize.html).

```kdl
window-rule {
    open-maximized-to-edges true
}
```

You can also set this to `false` to *prevent* a window from opening maximized to edges.

```kdl
window-rule {
    open-maximized-to-edges false
}
```

#### `open-fullscreen`

Make the window open [fullscreen](https://niri-wm.github.io/niri/Fullscreen-and-Maximize.html).

```kdl
window-rule {
    open-fullscreen true
}
```

You can also set this to `false` to *prevent* a window from opening fullscreen.

```kdl
// Make the Telegram media viewer open in windowed mode.
window-rule {
    match app-id=r#"^org\.telegram\.desktop$"# title="^Media viewer$"

    open-fullscreen false
}
```

#### `open-floating`

<sup>Since: 25.01</sup>

Make the window open in the floating layout.

```kdl
// Open the Firefox picture-in-picture window as floating.
window-rule {
    match app-id="firefox$" title="^Picture-in-Picture$"

    open-floating true
}
```

You can also set this to `false` to *prevent* a window from opening in the floating layout.

```kdl
// Open all windows in the tiling layout, overriding any auto-floating logic.
window-rule {
    open-floating false
}
```

#### `open-focused`

<sup>Since: 25.01</sup>

Set this to `false` to prevent this window from being automatically focused upon opening.

```kdl
// Don't give focus to the GIMP startup splash screen.
window-rule {
    match app-id="^gimp" title="^GIMP Startup$"

    open-focused false
}
```

You can also set this to `true` to focus the window, even if normally it wouldn't get auto-focused.

```kdl
// Always focus the KeePassXC-Browser unlock dialog.
//
// This dialog opens parented to the KeePassXC window rather than the browser,
// so it doesn't get auto-focused by default.
window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"# title="^Unlock Database - KeePassXC$"

    open-focused true
}
```

### Dynamic Properties

These properties apply continuously to open windows.

#### `block-out-from`

You can block out windows from xdg-desktop-portal screencasts.
They will be replaced with solid black rectangles.

This can be useful for password managers or messenger windows, etc.
For layer-shell notification pop-ups and the like, you can use a [`block-out-from` layer rule](https://niri-wm.github.io/niri/Configuration%3A-Layer-Rules.html#block-out-from).

![Screenshot showing a window visible normally, but blocked out on OBS.](https://niri-wm.github.io/niri/img%2Fblock-out-from-screencast.png)

To preview and set up this rule, check the `preview-render` option in the debug section of the config.

> [!CAUTION]
> The window is **not** blocked out from third-party screenshot tools.
> If you open some screenshot tool with preview while screencasting, blocked out windows **will be visible** on the screencast.

The built-in screenshot UI is not affected by this problem though.
If you open the screenshot UI while screencasting, you will be able to select the area to screenshot while seeing all windows normally, but on a screencast the selection UI will display with windows blocked out.

```kdl
// Block out password managers from screencasts.
window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#

    block-out-from "screencast"
}
```

Alternatively, you can block out the window out of *all* screen captures, including third-party screenshot tools.
This way you avoid accidentally showing the window on a screencast when opening a third-party screenshot preview.

This setting will still let you use the interactive built-in screenshot UI, but it will block out the window from the fully automatic screenshot actions, such as `screenshot-screen` and `screenshot-window`.
The reasoning is that with an interactive selection, you can make sure that you avoid screenshotting sensitive content.

```kdl
window-rule {
    block-out-from "screen-capture"
}
```

> [!WARNING]
> Be careful when blocking out windows based on a dynamically changing window title.
>
> For example, you might try to block out specific Firefox tabs like this:
>
> ```kdl
> window-rule {
>     // Doesn't quite work! Try to block out the Gmail tab.
>     match app-id="firefox$" title="- Gmail "
>
>     block-out-from "screencast"
> }
> ```
>
> It will work, but when switching from a sensitive tab to a regular tab, the contents of the sensitive tab **will show up on a screencast** for an instant.
>
> This is because window title (and app ID) are not double-buffered in the Wayland protocol, so they are not tied to specific window contents.
> There's no robust way for Firefox to synchronize visibly showing a different tab and changing the window title.

#### `opacity`

Set the opacity of the window.
`0.0` is fully transparent, `1.0` is fully opaque.
This is applied on top of the window's own opacity, so semitransparent windows will become even more transparent.

Opacity is applied to every surface of the window individually, so subsurfaces and pop-up menus will show window content behind them.

![Screenshot showing Adwaita Demo with a semitransparent pop-up menu.](https://niri-wm.github.io/niri/img%2Fopacity-popup.png)

Also, focus ring and border with background will show through semitransparent windows (see `prefer-no-csd` and the `draw-border-with-background` window rule below).

Opacity can be toggled on or off for a window using the [`toggle-window-rule-opacity`](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html#toggle-window-rule-opacity) action.

```kdl
// Make inactive windows semitransparent.
window-rule {
    match is-active=false

    opacity 0.95
}
```

#### `variable-refresh-rate`

<sup>Since: 0.1.9</sup>

If set to true, whenever this window displays on an output with on-demand VRR, it will enable VRR on that output.

```kdl
// Configure some output with on-demand VRR.
output "HDMI-A-1" {
    variable-refresh-rate on-demand=true
}

// Enable on-demand VRR when mpv displays on the output.
window-rule {
    match app-id="^mpv$"

    variable-refresh-rate true
}
```

#### `default-column-display`

<sup>Since: 25.02</sup>

Set the default display mode for columns created from this window.
Can be `normal` or `tabbed`.

This is used any time a window goes into its own column.
For example:
- Opening a new window.
- Expelling a window into its own column.
- Moving a window from the floating layout to the tiling layout.

```kdl
// Make Evince windows open as tabbed columns.
window-rule {
    match app-id="^evince$"

    default-column-display "tabbed"
}
```

#### `default-floating-position`

<sup>Since: 25.01</sup>

Set the initial position for this window when it opens on, or moves to the floating layout.

Afterward, the window will remember its last floating position.

By default, new floating windows open at the center of the screen, and windows from the tiling layout open close to their visual screen position.

The position uses logical coordinates relative to the working area.
By default, they are relative to the top-left corner of the working area, but you can change this by setting `relative-to` to one of these values: `top-left`, `top-right`, `bottom-left`, `bottom-right`, `top`, `bottom`, `left`, or `right`.

For example, if you have a bar at the top, then `x=0 y=0` will put the top-left corner of the window directly below the bar.
If instead you write `x=0 y=0 relative-to="top-right"`, then the top-right corner of the window will align with the top-right corner of the workspace, also directly below the bar.
When only one side is specified (e.g. top) the window will align to the center of that side.

The coordinates change direction based on `relative-to`.
For example, by default (top-left), `x=100 y=200` will put the window 100 pixels to the right and 200 pixels down from the top-left corner.
If you use `x=100 y=200 relative-to="bottom-left"`, it will put the window 100 pixels to the right and 200 pixels *up* from the bottom-left corner.

```kdl
// Open the Firefox picture-in-picture window at the bottom-left corner of the screen
// with a small gap.
window-rule {
    match app-id="firefox$" title="^Picture-in-Picture$"

    default-floating-position x=32 y=32 relative-to="bottom-left"
}
```

You can use single-side `relative-to` to get a dropdown-like effect.

```kdl
// Example: a "dropdown" terminal.
window-rule {
    // Match by "dropdown" app ID.
    // You need to set this app ID when running your terminal, e.g.:
    // spawn "alacritty" "--class" "dropdown"
    match app-id="^dropdown$"

    // Open it as floating.
    open-floating true
    // Anchor to the top edge of the screen.
    default-floating-position x=0 y=0 relative-to="top"
    // Half of the screen high.
    default-window-height { proportion 0.5; }
    // 80% of the screen wide.
    default-column-width { proportion 0.8; }
}
```

#### `scroll-factor`

<sup>Since: 25.02</sup>

Set a scroll factor for all scroll events sent to a window.

This will be multiplied with the scroll factor set for your input device in the [input section](https://niri-wm.github.io/niri/Configuration%3A-Input.html#pointing-devices).

```kdl
// Make scrolling in Firefox a bit slower.
window-rule {
    match app-id="firefox$"

    scroll-factor 0.75
}
```

#### `draw-border-with-background`

Override whether the border and the focus ring draw with a background.

Set this to `true` to draw them as solid colored rectangles even for windows which agreed to omit their client-side decorations.
Set this to `false` to draw them as borders around the window even for windows which use client-side decorations.

This property can be useful for rectangular windows that do not support the xdg-decoration protocol.

| With Background                                  | Without Background                                  |
| ------------------------------------------------ | --------------------------------------------------- |
| ![A screenshot displaying a window with draw-border-with-background set to true](https://niri-wm.github.io/niri/img%2Fsimple-egl-border-with-background.png) | ![A screenshot displaying a window with draw-border-with-background set to false](https://niri-wm.github.io/niri/img%2Fsimple-egl-border-without-background.png) |

```kdl
window-rule {
    draw-border-with-background false
}
```

#### `focus-ring` and `border`

<sup>Since: 0.1.6</sup>

Override the focus ring and border options for the window.

These rules have the same options as the normal [`focus-ring` and `border` config in the layout section](https://niri-wm.github.io/niri/Configuration%3A-Layout.html#focus-ring-and-border), so check the documentation there.

However, in addition to `off` to disable the border/focus ring, this window rule has an `on` flag that enables the border/focus ring for the window even if it was otherwise disabled.
The `on` flag has precedence over the `off` flag, in case both are set.

```kdl
window-rule {
    focus-ring {
        off
        width 2
    }
}

window-rule {
    border {
        on
        width 8
    }
}
```

#### `shadow`

<sup>Since: 25.02</sup>

Override the shadow options for the window.

This rule has the same options as the normal [`shadow` config in the layout section](https://niri-wm.github.io/niri/Configuration%3A-Layout.html#shadow), so check the documentation there.

However, in addition to `on` to enable the shadow, this window rule has an `off` flag that disables the shadow for the window even if it was otherwise enabled.
The `on` flag has precedence over the `off` flag, in case both are set.

```kdl
// Turn on shadows for floating windows.
window-rule {
    match is-floating=true

    shadow {
        on
    }
}
```

#### `tab-indicator`

<sup>Since: 25.02</sup>

Override the tab indicator options for the window.

Options in this rule match the same options as the normal [`tab-indicator` config in the layout section](https://niri-wm.github.io/niri/Configuration%3A-Layout.html#tab-indicator), so check the documentation there.

```kdl
// Make KeePassXC tab have a dark red inactive color.
window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#

    tab-indicator {
        inactive-color "darkred"
    }
}
```

#### `geometry-corner-radius`

<sup>Since: 0.1.6</sup>

Set the corner radius of the window.

On its own, this setting will only affect the border and the focus ring—they will round their corners to match the geometry corner radius.
If you'd like to force-round the corners of the window itself, set [`clip-to-geometry true`](#clip-to-geometry) in addition to this setting.

```kdl
window-rule {
    geometry-corner-radius 12
}
```

The radius is set in logical pixels, and controls the radius of the window itself, that is, the inner radius of the border:

![A screenshot showing a window with every corner rounded](https://niri-wm.github.io/niri/img%2Fgeometry-corner-radius.png)

Instead of one radius, you can set four, for each corner.
The order is the same as in CSS: top-left, top-right, bottom-right, bottom-left.

```kdl
window-rule {
    geometry-corner-radius 8 8 0 0
}
```

This way, you can match GTK 3 applications which have square bottom corners:

![A screenshot showing a window with only the top corners rounded](https://niri-wm.github.io/niri/img%2Fdifferent-corner-radius.png)

#### `clip-to-geometry`

<sup>Since: 0.1.6</sup>

Clips the window to its visual geometry.

This will cut out any client-side window shadows, and also round window corners according to `geometry-corner-radius`.

![A screenshot showing a window with rounded corners, clipped to the visual geometry](https://niri-wm.github.io/niri/img%2Fclip-to-geometry.png)

```kdl
window-rule {
    clip-to-geometry true
}
```

Enable border, set [`geometry-corner-radius`](#geometry-corner-radius) and `clip-to-geometry`, and you've got a classic setup:

![A screenshot showing a window with rounded corners, and a border](https://niri-wm.github.io/niri/img%2Fborder-radius-clip.png)

```kdl
prefer-no-csd

layout {
    focus-ring {
        off
    }

    border {
        width 2
    }
}

window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}
```

#### `tiled-state`

<sup>Since: 25.05</sup>

Informs the window that it is tiled.
Usually, windows will react by becoming rectangular and hiding their client-side shadows.
Windows that snap their size to a grid (e.g. terminals like [foot](https://codeberg.org/dnkl/foot)) will usually disable this snapping when they are tiled.

By default, niri will set the tiled state to `true` together with [`prefer-no-csd`](https://niri-wm.github.io/niri/Configuration%3A-Miscellaneous.html#prefer-no-csd) in order to improve behavior for apps that don't support server-side decorations.
You can use this window rule to override this, for example to get rectangular windows with CSD.

```kdl
// Make tiled windows rectangular while using CSD.
window-rule {
    match is-floating=false

    tiled-state true
}
```

#### `baba-is-float`

<sup>Since: 25.02</sup>

Make your windows FLOAT up and down.

This is an April Fools' 2025 feature.

```kdl
window-rule {
    match is-floating=true

    baba-is-float true
}
```

<video controls src="https://github.com/user-attachments/assets/3f4cb1a4-40b2-4766-98b7-eec014c19509">

https://github.com/user-attachments/assets/3f4cb1a4-40b2-4766-98b7-eec014c19509

</video>

#### `background-effect`

<sup>Since: 26.04</sup>

Override the background effect options for this window.

- `xray`: set to `true` to enable the xray effect, or `false` to disable it.
- `blur`: set to `true` to enable blur behind this window, or `false` to force-disable it.
- `noise`: amount of pixel noise added to the background (helps with color banding from blur).
- `saturation`: color saturation of the background (`0` is desaturated, `1` is normal, `2` is 200% saturation).

See the [window effects page](https://niri-wm.github.io/niri/Window-Effects.html) for an overview of background effects.

```kdl
// Make floating windows use the regular blur (if enabled),
// while tiled windows keep using the efficient xray blur.
//
// Warning: non-xray blur is currently experimental and has known limitations.
// In particular, it doesn't work during window opening and closing animations.
window-rule {
    match is-floating=true

    background-effect {
        xray false
    }
}
```

#### `popups`

<sup>Since: 26.04</sup>

Override properties for this window's pop-ups (menus and tooltips).

The properties work the same way as the corresponding window-rule properties, except that they apply to the window's pop-ups rather than to the window itself.

`opacity` is applied *on top* of the layer surface's own opacity rule, so setting both will make pop-ups more transparent than the surface.
Other properties apply independently.

> [!NOTE]
> This block affects only pop-ups created by the app via Wayland's [xdg-popup](https://wayland.app/protocols/xdg-shell#xdg_popup) (which should be most of them).
>
> Examples of things that look like pop-ups that won't work:
>
> - Fully emulated by the client, i.e. not a pop-up at all, the client just draws something that looks like a pop-up inside its window.
> These are common in game engines and in web apps, e.g. the right click menu in Google Docs or in Electron apps like Discord.
>
> - Uses a wl-subsurface instead of an xdg-popup.
> Common in older apps using GTK 3, notably Firefox still uses these for some menus.
> Subsurfaces are an indivisible part of a surface and they aren't usually pop-ups, so it wouldn't make sense for niri to apply these rules to them.
>
> These emulated pop-ups come with other downsides: they cannot reliably extend outside their window, and if the app tries to do that, they will be clipped by rules such as `clip-to-geometry`.
> So most modern apps will correctly use xdg-popup, which is the intended way to show pop-ups on Wayland.
>
> This block also does not affect input-method pop-ups, such as Fcitx.
>
> For pop-ups created by your desktop shell or desktop components, use the corresponding [layer rule](https://niri-wm.github.io/niri/Configuration%3A-Layer-Rules.html#popups).

```kdl
// Blur the background behind pop-up menus in Nautilus.
window-rule {
    match app-id="Nautilus"

    popups {
        // Matches the default libadwaita pop-up corner radius.
        geometry-corner-radius 15

        // Note: it'll look better to set background opacity
        // through your GTK theme CSS and not here.
        // This is just an example that makes it look obvious.
        opacity 0.5

        background-effect {
            blur true
        }
    }
}
```

Keep in mind that the background effect will look right only if the pop-up is shaped like a (rounded) rectangle, and the window correctly sets its Wayland geometry to exclude any shadows.
For example, GTK 4 pop-ups with pointing arrows (`has-arrow=true` property) are *not* rounded rectangles—the arrow sticks out—so if you enable blur, it will also stick out of the pop-up.

| Correct                                             | Wrong                                                                          |
|-----------------------------------------------------|--------------------------------------------------------------------------------|
| The pop-up is a rounded rectangle. Blur looks fine. | The pop-up is not a rounded rectangle. Blur extends above, where the arrow is. |
| ![](https://niri-wm.github.io/niri/img%2Fpopup-no-arrow.png)                       | ![](https://niri-wm.github.io/niri/img%2Fpopup-arrow.png)                                                     |

These pop-ups with custom shapes will need the app to implement the [ext-background-effect protocol](https://wayland.app/protocols/ext-background-effect-v1) to work properly.

#### Size Overrides

You can amend the window's minimum and maximum size in logical pixels.

Keep in mind that the window itself always has a final say in its size.
These values instruct niri to never ask the window to be smaller than the minimum you set, or to be bigger than the maximum you set.

> [!NOTE]
> `max-height` will only apply to automatically-sized windows if it is equal to `min-height`.
> Either set it equal to `min-height`, or change the window height manually after opening it with `set-window-height`.
>
> This is a limitation of niri's window height distribution algorithm.

```kdl
window-rule {
    min-width 100
    max-width 200
    min-height 300
    max-height 300
}
```

```kdl
// Fix OBS with server-side decorations missing a minimum width.
window-rule {
    match app-id=r#"^com\.obsproject\.Studio$"#

    min-width 876
}
```



## Layer Rules


### Overview

<sup>Since: 25.01</sup>

Layer rules let you adjust behavior for individual layer-shell surfaces.
They have `match` and `exclude` directives that control which layer-shell surfaces the rule should apply to, and a number of properties that you can set.

Layer rules are processed and work very similarly to window rules, just with different matchers and properties.
Please read the [window rules wiki page](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html) to learn how matching works.

Here are all matchers and properties that a layer rule could have:

```kdl
layer-rule {
    match namespace="waybar"
    match at-startup=true
    match layer="top"

    // Properties that apply continuously.
    opacity 0.5
    block-out-from "screencast"
    // block-out-from "screen-capture"

    shadow {
        on
        // off
        softness 40
        spread 5
        offset x=0 y=5
        draw-behind-window true
        color "#00000064"
        // inactive-color "#00000064"
    }

    geometry-corner-radius 12
    place-within-backdrop true
    baba-is-float true

    background-effect {
        xray true
        blur true
        noise 0.05
        saturation 3
    }

    popups {
        opacity 0.5
        geometry-corner-radius 6

        background-effect {
            xray true
            blur true
            noise 0.05
            saturation 3
        }
    }
}
```

### Layer Surface Matching

Let's look at the matchers in more detail.

#### `namespace`

This is a regular expression that should match anywhere in the surface namespace.
You can read about the supported regular expression syntax [here](https://docs.rs/regex/latest/regex/#syntax).

```kdl
// Match surfaces with namespace containing "waybar",
layer-rule {
    match namespace="waybar"
}
```

You can find the namespaces of all open layer-shell surfaces by running `niri msg layers`.

#### `at-startup`

Can be `true` or `false`.
Matches during the first 60 seconds after starting niri.

```kdl
// Show layer-shell surfaces with 0.5 opacity at niri startup, but not afterwards.
layer-rule {
    match at-startup=true

    opacity 0.5
}
```

#### `layer`

<sup>Since: 26.04</sup>

Matches surfaces on this layer-shell layer.
Can be `"background"`, `"bottom"`, `"top"`, or `"overlay"`.

```kdl
// Make all overlay-layer surfaces FLOAT.
layer-rule {
    match layer="overlay"

    baba-is-float true
}
```

### Dynamic Properties

These properties apply continuously to open layer-shell surfaces.

#### `block-out-from`

You can block out surfaces from xdg-desktop-portal screencasts or all screen captures.
They will be replaced with solid black rectangles.

This can be useful for notifications.

The same caveats and instructions apply as for the [`block-out-from` window rule](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#block-out-from), so check the documentation there.

![Screenshot showing a notification visible normally, but blocked out on OBS.](https://niri-wm.github.io/niri/img%2Flayer-block-out-from-screencast.png)

```kdl
// Block out mako notifications from screencasts.
layer-rule {
    match namespace="^notifications$"

    block-out-from "screencast"
}
```

#### `opacity`

Set the opacity of the surface.
`0.0` is fully transparent, `1.0` is fully opaque.
This is applied on top of the surface's own opacity, so semitransparent surfaces will become even more transparent.

Opacity is applied to every child of the layer-shell surface individually, so subsurfaces and pop-up menus will show window content behind them.

```kdl
// Make fuzzel semitransparent.
layer-rule {
    match namespace="^launcher$"

    opacity 0.95
}
```

#### `shadow`

<sup>Since: 25.02</sup>

Override the shadow options for the surface.

These rules have the same options as the normal [`shadow` config in the layout section](https://niri-wm.github.io/niri/Configuration%3A-Layout.html#shadow), so check the documentation there.

Unlike window shadows, layer surface shadows always need to be enabled with a layer rule.
That is, enabling shadows in the layout config section won't automatically enable them for layer surfaces.

> [!NOTE]
> Layer surfaces have no way to tell niri about their *visual geometry*.
> For example, if a layer surface includes some invisible margins (like mako), niri has no way of knowing that, and will draw the shadow behind the entire surface, including the invisible margins.
>
> So to use niri shadows, you'll need to configure layer-shell clients to remove their own margins or shadows.

```kdl
// Add a shadow for fuzzel.
layer-rule {
    match namespace="^launcher$"

    shadow {
        on
    }

    // Fuzzel defaults to 10 px rounded corners.
    geometry-corner-radius 10
}
```

#### `geometry-corner-radius`

<sup>Since: 25.02</sup>

Set the corner radius of the surface.

This setting will only affect the shadow—it will round its corners to match the geometry corner radius.

```kdl
layer-rule {
    match namespace="^launcher$"

    geometry-corner-radius 12
}
```

#### `place-within-backdrop`

<sup>Since: 25.05</sup>

Set to `true` to place the surface into the backdrop visible in the [Overview](https://niri-wm.github.io/niri/Overview.html) and between workspaces.

This will only work for *background* layer surfaces that ignore exclusive zones (typical for wallpaper tools).
Layers within the backdrop will ignore all input.

```kdl
// Put swaybg inside the overview backdrop.
layer-rule {
    match namespace="^wallpaper$"

    place-within-backdrop true
}
```

#### `baba-is-float`

<sup>Since: 25.05</sup>

Make your layer surfaces FLOAT up and down.

This is a natural extension of the [April Fools' 2025 feature](https://niri-wm.github.io/niri/Configuration%3A-Window-Rules.html#baba-is-float).

```kdl
// Make fuzzel FLOAT.
layer-rule {
    match namespace="^launcher$"

    baba-is-float true
}
```

#### `background-effect`

<sup>Since: 26.04</sup>

Override the background effect options for this surface.

- `xray`: set to `true` to enable the xray effect, or `false` to disable it.
- `blur`: set to `true` to enable blur behind this surface, or `false` to force-disable it.
- `noise`: amount of pixel noise added to the background (helps with color banding from blur).
- `saturation`: color saturation of the background (`0` is desaturated, `1` is normal, `2` is 200% saturation).

See the [window effects page](https://niri-wm.github.io/niri/Window-Effects.html) for an overview of background effects.

```kdl
// Make top and overlay layers use the regular blur (if enabled),
// while bottom and background layers keep using the efficient xray blur.
layer-rule {
    match layer="top"
    match layer="overlay"

    background-effect {
        xray false
    }
}
```

#### `popups`

<sup>Since: 26.04</sup>

Override properties for this layer surface's pop-ups (e.g. a menu opened by clicking an item in Waybar).

The properties work the same way as the corresponding layer-rule properties, except that they apply to the layer surface's pop-ups rather than to the layer surface itself.

`opacity` is applied *on top* of the layer surface's own opacity rule, so setting both will make pop-ups more transparent than the surface.
Other properties apply independently.

> [!NOTE]
> This block affects only pop-ups created by the app via Wayland's [xdg-popup](https://wayland.app/protocols/xdg-shell#xdg_popup) (which should be most of them).
>
> Some desktop shells will emulate pop-ups by drawing something that looks like a pop-up inside a regular layer surface.
> As far as niri is concerned, those are just layer surfaces and not pop-ups, so this block won't apply to them.
>
> This block also does not affect input-method pop-ups, such as Fcitx.

```kdl
// Blur the background behind Waybar popup menus.
layer-rule {
    match namespace="^waybar$"

    popups {
        // Match the default GTK 3 popup corner radius.
        geometry-corner-radius 6
        opacity 0.85

        background-effect {
            blur true
        }
    }
}
```

Keep in mind that the background effect will look right only if the pop-up is shaped like a (rounded) rectangle, and the layer surface correctly sets its Wayland geometry to exclude any shadows.
Pop-ups with custom shapes will need the app to implement the [ext-background-effect protocol](https://wayland.app/protocols/ext-background-effect-v1) to work properly.



## Animations


### Overview

Niri has several animations which you can configure in the same way.
Additionally, you can disable or slow down all animations at once.

Here's a quick glance at the available animations with their default values.

```kdl
animations {
    // Uncomment to turn off all animations.
    // You can also put "off" into each individual animation to disable it.
    // off

    // Slow down all animations by this factor. Values below 1 speed them up instead.
    // slowdown 3.0

    // Individual animations.

    workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
    }

    window-open {
        duration-ms 150
        curve "ease-out-expo"
    }

    window-close {
        duration-ms 150
        curve "ease-out-quad"
    }

    horizontal-view-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }

    window-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }

    window-resize {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }

    config-notification-open-close {
        spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
    }

    exit-confirmation-open-close {
        spring damping-ratio=0.6 stiffness=500 epsilon=0.01
    }

    screenshot-ui-open {
        duration-ms 200
        curve "ease-out-quad"
    }

    overview-open-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }

    recent-windows-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.001
    }
}
```

### Animation Types

There are two animation types: easing and spring.
Each animation can be either an easing or a spring.

#### Easing

This is a relatively common animation type that changes the value over a set duration using an interpolation curve.

To use this animation, set the following parameters:

- `duration-ms`: duration of the animation in milliseconds.
- `curve`: the easing curve to use.

```kdl
animations {
    window-open {
        duration-ms 150
        curve "ease-out-expo"
    }
}
```

Currently, niri only supports five curves.
You can get a feel for them on pages like [easings.net](https://easings.net/).

- `ease-out-quad` <sup>Since: 0.1.5</sup>
- `ease-out-cubic`
- `ease-out-expo`
- `linear` <sup>Since: 0.1.6</sup>
- `cubic-bezier` <sup>Since: 25.08</sup>
    A custom [cubic Bézier curve](https://www.w3.org/TR/css-easing-1/#cubic-bezier-easing-functions). You need to set 4 numbers defining the control points of the curve, for example:
    ```kdl
    animations {
        window-open {
            // Same as CSS cubic-bezier(0.05, 0.7, 0.1, 1)
            curve "cubic-bezier" 0.05 0.7 0.1 1
        }
    }
    ```
    You can tweak the cubic-bezier parameters on pages like [easings.co](https://easings.co?curve=0.05,0.7,0.1,1).

#### Spring

Spring animations use a model of a physical spring to animate the value.
They notably feel better with touchpad gestures, because they take into account the velocity of your fingers as you release the swipe.
Springs can also oscillate / bounce at the end with the right parameters if you like that sort of thing, but they don't have to (and by default they mostly don't).

Due to springs using a physical model, the animation parameters are less obvious and generally should be tuned with trial and error.
Notably, you cannot directly set the duration.
You can use the [Elastic](https://flathub.org/apps/app.drey.Elastic) app to help visualize how the spring parameters change the animation.

A spring animation is configured like this, with three mandatory parameters:

```kdl
animations {
    workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
    }
}
```

The `damping-ratio` goes from 0.1 to 10.0 and has the following properties:

- below 1.0: underdamped spring, will oscillate in the end.
- above 1.0: overdamped spring, won't oscillate.
- 1.0: critically damped spring, comes to rest in minimum possible time without oscillations.

However, even with damping ratio = 1.0, the spring animation may oscillate if "launched" with enough velocity from a touchpad swipe.

> [!WARNING]
> Overdamped springs currently have some numerical stability issues and may cause graphical glitches.
> Therefore, setting `damping-ratio` above `1.0` is not recommended.

Lower `stiffness` will result in a slower animation more prone to oscillation.

Set `epsilon` to a lower value if the animation "jumps" at the end.

> [!TIP]
> The spring *mass* (which you can see in Elastic) is hardcoded to 1.0 and cannot be changed.
> Instead, change `stiffness` proportionally.
> E.g. increasing mass by 2× is the same as decreasing stiffness by 2×.

### Animations

Now let's go into more detail on the animations that you can configure.

#### `workspace-switch`

Animation when switching workspaces up and down, including after the vertical touchpad gesture (a spring is recommended).

```kdl
animations {
    workspace-switch {
        spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
    }
}
```

#### `window-open`

Window opening animation.

This one uses an easing type by default.

```kdl
animations {
    window-open {
        duration-ms 150
        curve "ease-out-expo"
    }
}
```

##### `custom-shader`

<sup>Since: 0.1.6</sup>

You can write a custom shader for drawing the window during an open animation.

See [this example shader](https://niri-wm.github.io/niri/examples%2Fopen_custom_shader.frag) for a full documentation with several animations to experiment with.

If a custom shader fails to compile, niri will print a warning and fall back to the default, or previous successfully compiled shader.
When running niri as a systemd service, you can see the warnings in the journal: `journalctl -ef /usr/bin/niri`

> [!WARNING]
>
> Custom shaders do not have a backwards compatibility guarantee.
> I may need to change their interface as I'm developing new features.

Example: open will fill the current geometry with a solid gradient that gradually fades in.

```kdl
animations {
    window-open {
        duration-ms 250
        curve "linear"

        custom-shader r"
            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                vec4 color = vec4(0.0);

                if (0.0 <= coords_geo.x && coords_geo.x <= 1.0
                        && 0.0 <= coords_geo.y && coords_geo.y <= 1.0)
                {
                    vec4 from = vec4(1.0, 0.0, 0.0, 1.0);
                    vec4 to = vec4(0.0, 1.0, 0.0, 1.0);
                    color = mix(from, to, coords_geo.y);
                }

                return color * niri_clamped_progress;
            }
        "
    }
}
```

#### `window-close`

<sup>Since: 0.1.5</sup>

Window closing animation.

This one uses an easing type by default.

```kdl
animations {
    window-close {
        duration-ms 150
        curve "ease-out-quad"
    }
}
```

##### `custom-shader`

<sup>Since: 0.1.6</sup>

You can write a custom shader for drawing the window during a close animation.

See [this example shader](https://niri-wm.github.io/niri/examples%2Fclose_custom_shader.frag) for a full documentation with several animations to experiment with.

If a custom shader fails to compile, niri will print a warning and fall back to the default, or previous successfully compiled shader.
When running niri as a systemd service, you can see the warnings in the journal: `journalctl -ef /usr/bin/niri`

> [!WARNING]
>
> Custom shaders do not have a backwards compatibility guarantee.
> I may need to change their interface as I'm developing new features.

Example: close will fill the current geometry with a solid gradient that gradually fades away.

```kdl
animations {
    window-close {
        custom-shader r"
            vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                vec4 color = vec4(0.0);

                if (0.0 <= coords_geo.x && coords_geo.x <= 1.0
                        && 0.0 <= coords_geo.y && coords_geo.y <= 1.0)
                {
                    vec4 from = vec4(1.0, 0.0, 0.0, 1.0);
                    vec4 to = vec4(0.0, 1.0, 0.0, 1.0);
                    color = mix(from, to, coords_geo.y);
                }

                return color * (1.0 - niri_clamped_progress);
            }
        "
    }
}
```

#### `horizontal-view-movement`

All horizontal camera view movement animations, such as:

- When a window off-screen is focused and the camera scrolls to it.
- When a new window appears off-screen and the camera scrolls to it.
- After a horizontal touchpad gesture (a spring is recommended).

```kdl
animations {
    horizontal-view-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }
}
```

#### `window-movement`

<sup>Since: 0.1.5</sup>

Movement of individual windows within a workspace.

Includes:

- Moving window columns with `move-column-left` and `move-column-right`.
- Moving windows inside a column with `move-window-up` and `move-window-down`.
- Moving windows out of the way upon window opening and closing.
- Window movement between columns when consuming/expelling.

This animation *does not* include the camera view movement, such as scrolling the workspace left and right.

```kdl
animations {
    window-movement {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }
}
```

#### `window-resize`

<sup>Since: 0.1.5</sup>

Window resize animation.

Only manual window resizes are animated, i.e. when you resize the window with `switch-preset-column-width` or `maximize-column`.
Also, very small resizes (up to 10 pixels) are not animated.

```kdl
animations {
    window-resize {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }
}
```

##### `custom-shader`

<sup>Since: 0.1.6</sup>

You can write a custom shader for drawing the window during a resize animation.

See [this example shader](https://niri-wm.github.io/niri/examples%2Fresize_custom_shader.frag) for a full documentation with several animations to experiment with.

If a custom shader fails to compile, niri will print a warning and fall back to the default, or previous successfully compiled shader.
When running niri as a systemd service, you can see the warnings in the journal: `journalctl -ef /usr/bin/niri`

> [!WARNING]
>
> Custom shaders do not have a backwards compatibility guarantee.
> I may need to change their interface as I'm developing new features.

Example: resize will show the next (after resize) window texture right away, stretched to the current geometry.

```kdl
animations {
    window-resize {
        custom-shader r"
            vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
                vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
                vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
                return color;
            }
        "
    }
}
```

#### `config-notification-open-close`

The open/close animation of the config parse error and new default config notifications.

This one uses an underdamped spring by default (`damping-ratio=0.6`) which causes a slight oscillation in the end.

```kdl
animations {
    config-notification-open-close {
        spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
    }
}
```

#### `exit-confirmation-open-close`

<sup>Since: 25.08</sup>

The open/close animation of the exit confirmation dialog.

This one uses an underdamped spring by default (`damping-ratio=0.6`) which causes a slight oscillation in the end.

```kdl
animations {
    exit-confirmation-open-close {
        spring damping-ratio=0.6 stiffness=500 epsilon=0.01
    }
}
```

#### `screenshot-ui-open`

<sup>Since: 0.1.8</sup>

The open (fade-in) animation of the screenshot UI.

```kdl
animations {
    screenshot-ui-open {
        duration-ms 200
        curve "ease-out-quad"
    }
}
```

#### `overview-open-close`

<sup>Since: 25.05</sup>

The open/close zoom animation of the [Overview](https://niri-wm.github.io/niri/Overview.html).

```kdl
animations {
    overview-open-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
    }
}
```

#### `recent-windows-close`

<sup>Since: 25.11</sup>

The close fade-out animation of the recent windows switcher.

```kdl
animations {
    recent-windows-close {
        spring damping-ratio=1.0 stiffness=800 epsilon=0.001
    }
}
```

### Synchronized Animations

<sup>Since: 0.1.5</sup>

Sometimes, when two animations are meant to play together synchronized, niri will drive them both with the same configuration.

For example, if a window resize causes the view to move, then that view movement animation will also use the `window-resize` configuration (rather than the `horizontal-view-movement` configuration).
This is especially important for animated resizes to look good when using `center-focused-column "always"`.

As another example, resizing a window in a column vertically causes other windows to move up or down into their new position.
This movement will use the `window-resize` configuration, rather than the `window-movement` configuration, to keep the animations synchronized.

A few actions are still missing this synchronization logic, since in some cases it is difficult to implement properly.
Therefore, for the best results, consider using the same parameters for related animations (they are all the same by default):

- `horizontal-view-movement`
- `window-movement`
- `window-resize`



## Gestures


### Overview

<sup>Since: 25.02</sup>

The `gestures` config section contains gesture settings.
For an overview of all niri gestures, see the [Gestures](https://niri-wm.github.io/niri/Gestures.html) wiki page.

Here's a quick glance at the available settings along with their default values.

```kdl
gestures {
    dnd-edge-view-scroll {
        trigger-width 30
        delay-ms 100
        max-speed 1500
    }

    dnd-edge-workspace-switch {
        trigger-height 50
        delay-ms 100
        max-speed 1500
    }

    hot-corners {
        // off
        top-left
        // top-right
        // bottom-left
        // bottom-right
    }
}
```

### `dnd-edge-view-scroll`

Scroll the tiling view when moving the mouse cursor against a monitor edge during drag-and-drop (DnD).
Also works on a touchscreen.

This will work for regular drag-and-drop (e.g. dragging a file from a file manager), and for window interactive move when targeting the tiling layout.

The options are:

- `trigger-width`: size of the area near the monitor edge that will trigger the scrolling, in logical pixels.
- `delay-ms`: delay in milliseconds before the scrolling starts.
Avoids unwanted scrolling when dragging things across monitors.
- `max-speed`: maximum scrolling speed in logical pixels per second.
The scrolling speed increases linearly as you move your mouse cursor from `trigger-width` to the very edge of the monitor.

```kdl
gestures {
    // Increase the trigger area and maximum speed.
    dnd-edge-view-scroll {
        trigger-width 100
        max-speed 3000
    }
}
```

### `dnd-edge-workspace-switch`

<sup>Since: 25.05</sup>

Scroll the workspaces up/down when moving the mouse cursor against a monitor edge during drag-and-drop (DnD) while in the overview.
Also works on a touchscreen.

The options are:

- `trigger-height`: size of the area near the monitor edge that will trigger the scrolling, in logical pixels.
- `delay-ms`: delay in milliseconds before the scrolling starts.
Avoids unwanted scrolling when dragging things across monitors.
- `max-speed`: maximum scrolling speed; 1500 corresponds to one screen height per second.
The scrolling speed increases linearly as you move your mouse cursor from `trigger-width` to the very edge of the monitor.

```kdl
gestures {
    // Increase the trigger area and maximum speed.
    dnd-edge-workspace-switch {
        trigger-height 100
        max-speed 3000
    }
}
```

### `hot-corners`

<sup>Since: 25.05</sup>

Put your mouse at the very top-left corner of a monitor to toggle the overview.
Also works during drag-and-dropping something.

`off` disables the hot corners.

```kdl
// Disable the hot corners.
gestures {
    hot-corners {
        off
    }
}
```

<sup>Since: 25.11</sup> You can choose specific hot corners by name: `top-left`, `top-right`, `bottom-left`, `bottom-right`.
If no corners are explicitly set, the top-left corner will be active by default.

```kdl
// Enable the top-right and bottom-right hot corners.
gestures {
    hot-corners {
        top-right
        bottom-right
    }
}
```

You can also customize hot corners per-output [in the output config](https://niri-wm.github.io/niri/Configuration%3A-Outputs.html#hot-corners).



## Recent Windows


### Overview

<sup>Since: 25.11</sup>

In this section you can configure the recent windows switcher (Alt-Tab).

Here is an outline of the available settings and their default values:

```kdl
recent-windows {
    // off
    debounce-ms 750

    open-delay-ms 150

    highlight {
        active-color "#999999ff"
        urgent-color "#ff9999ff"
        padding 30
        corner-radius 0
    }

    previews {
        max-height 480
        max-scale 0.5
    }

    binds {
        Alt+Tab         { next-window; }
        Alt+Shift+Tab   { previous-window; }
        Alt+grave       { next-window     filter="app-id"; }
        Alt+Shift+grave { previous-window filter="app-id"; }

        Mod+Tab         { next-window; }
        Mod+Shift+Tab   { previous-window; }
        Mod+grave       { next-window     filter="app-id"; }
        Mod+Shift+grave { previous-window filter="app-id"; }
    }
}
```

`off` disables the recent windows switcher altogether.

### `debounce-ms`

Delay, in milliseconds, between the window receiving focus and getting "committed" to the recent windows list.

When you want to focus some window, you might end up focusing some unrelated windows on the way:

- with keyboard navigation, the windows between your current one and the target one;
- with [`focus-follows-mouse`](https://niri-wm.github.io/niri/Configuration%3A-Input.html#focus-follows-mouse), the windows you happen to cross with the mouse pointer on the way to the target window.

The debounce delay prevents those intermediate windows from polluting the recent windows list.

Note that some actions, like keyboard input into the target window, will skip this delay and commit the window to the list immediately.
This way, the recent windows list stays responsive while not getting polluted too much with unintended windows.

If you want windows to appear in recent windows right away, including intermediate windows, you can reduce the delay or set it to zero:

```kdl
recent-windows {
    // Commit windows to the recent windows list as soon as they're focused,
    // with no debounce delay.
    debounce-ms 0
}
```

### `open-delay-ms`

Delay, in milliseconds, between pressing the Alt-Tab bind and the recent windows switcher visually appearing on screen.

The switcher is delayed by default so that quickly tapping Alt-Tab to switch windows wouldn't cause annoying fullscreen visual changes.

```kdl
recent-windows {
    // Make the switcher appear instantly.
    open-delay-ms 0
}
```

### `highlight`

Controls the highlight behind the focused window preview in the recent windows switcher.

- `active-color`: normal color of the focused window highlight.
- `urgent-color`: color of an urgent focused window highlight, also visible in a darker shade on unfocused windows.
- `padding`: padding of the highlight around the window preview, in logical pixels.
- `corner-radius`: corner radius of the highlight.

```kdl
recent-windows {
    // Round the corners on the highlight.
    highlight {
        corner-radius 14
    }
}
```

### `previews`

Controls the window previews in the switcher.

- `max-scale`: maximum scale of the window previews.
Windows cannot be scaled bigger than this value.
- `max-height`: maximum height of the window previews.
Further limits the size of the previews in order to occupy less space on large monitors.

On smaller monitors, the previews will be primarily limited by `max-scale`, and on larger monitors they will be primarily limited by `max-height`.

The `max-scale` limit is imposed twice: on the final window scale, and on the window height which cannot exceed `monitor height × max scale`.

```kdl
recent-windows {
    // Make the previews smaller to fit more on screen.
    previews {
        max-height 320
    }
}
```

```kdl
recent-windows {
    // Make the previews larger to see the window contents.
    previews {
        max-height 1080
        max-scale 0.75
    }
}
```

### `binds`

Configure binds that open and navigate the recent windows switcher.

The defaults are <kbd>Alt</kbd><kbd>Tab</kbd> / <kbd>Mod</kbd><kbd>Tab</kbd> to switch across all windows, and <kbd>Alt</kbd><kbd>\`</kbd> / <kbd>Mod</kbd><kbd>\`</kbd> to switch between windows of the current application.
Adding <kbd>Shift</kbd> will switch windows backwards.

Adding the recent windows `binds {}` section to your config removes all default binds.
You can copy the ones you need from the summary at the top of this wiki page.

```kdl
recent-windows {
    // Even an empty binds {} section will remove all default binds.
    binds {
    }
}
```

The available actions are `next-window` and `previous-window`.
They can optionally have the following properties:

- `filter="app-id"`: filters the switcher to the windows of the currently selected application, as determined by the Wayland app ID.
- `scope="all"`, `scope="output"`, `scope="workspace"`: sets the pre-selected scope when this bind is used to open the recent windows switcher.

```kdl
recent-windows {
    // Pre-select the "Output" scope when switching windows.
    binds {
        Mod+Tab         { next-window     scope="output"; }
        Mod+Shift+Tab   { previous-window scope="output"; }
        Mod+grave       { next-window     scope="output" filter="app-id"; }
        Mod+Shift+grave { previous-window scope="output" filter="app-id"; }
    }
}
```

The recent windows binds have lower precedence than the [normal binds](https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html), meaning that if you have <kbd>Alt</kbd><kbd>Tab</kbd> bound to something else in the normal binds, the `recent-windows` bind won't work.
In this case, you can remove the conflicting normal bind.

All binds in this section must have a modifier key like <kbd>Alt</kbd> or <kbd>Mod</kbd> because the recent windows switcher remains open only while you hold any modifier key.

#### Bindings inside the switcher

When the switcher is open, some hardcoded binds are available:

- <kbd>Escape</kbd> cancels the switcher.
- <kbd>Enter</kbd> closes the switcher confirming the current window.
- <kbd>A</kbd>, <kbd>W</kbd>, <kbd>O</kbd> select a specific scope.
- <kbd>S</kbd> cycles between scopes, as indicated by the panel at the top.
- <kbd>←</kbd>, <kbd>→</kbd>, <kbd>Home</kbd>, <kbd>End</kbd> move the selection directionally.

Additionally, certain regular binds will automatically work in the switcher:

- focus column left/right and their variants: will move the selection left/right inside the switcher.
- focus column first/last: will move the selection to the first or last window.
- close window: will close the window currently focused in the switcher.
- screenshot: will open the screenshot UI.

The way this works is by finding all regular binds corresponding to these actions and taking just the trigger key without modifiers.
For example, if you have <kbd>Mod</kbd><kbd>Shift</kbd><kbd>C</kbd> bound to `close-window`, in the window switcher pressing <kbd>C</kbd> on its own will close the window.

This way we don't need to hardcode things like HJKL directional movements.
If you have, say, Colemak-DH MNEI binds instead, they will work for you in the window switcher (as long as they don't conflict with the hardcoded ones).



## Debug Options


### Overview

Niri has several options that are only useful for debugging, or are experimental and have known issues.
They are not meant for normal use.

> [!CAUTION]
> These options are **not** covered by the [config breaking change policy](https://niri-wm.github.io/niri/Configuration%3A-Introduction.html#breaking-change-policy).
> They can change or stop working at any point with little notice.

Here are all the options at a glance:

```kdl
debug {
    preview-render "screencast"
    // preview-render "screen-capture"
    enable-overlay-planes
    disable-cursor-plane
    disable-direct-scanout
    restrict-primary-scanout-to-matching-format
    force-disable-connectors-on-resume
    render-drm-device "/dev/dri/renderD129"
    ignore-drm-device "/dev/dri/renderD128"
    ignore-drm-device "/dev/dri/renderD130"
    force-pipewire-invalid-modifier
    dbus-interfaces-in-non-session-instances
    wait-for-frame-completion-before-queueing
    emulate-zero-presentation-time
    disable-resize-throttling
    disable-transactions
    keep-laptop-panel-on-when-lid-is-closed
    disable-monitor-names
    strict-new-window-focus-policy
    honor-xdg-activation-with-invalid-serial
    skip-cursor-only-updates-during-vrr
    deactivate-unfocused-windows
}

binds {
    Mod+Shift+Ctrl+T { toggle-debug-tint; }
    Mod+Shift+Ctrl+O { debug-toggle-opaque-regions; }
    Mod+Shift+Ctrl+D { debug-toggle-damage; }
}
```

### `preview-render`

Make niri render the monitors the same way as for a screencast or a screen capture.

Useful for previewing the `block-out-from` window rule.

```kdl
debug {
    preview-render "screencast"
    // preview-render "screen-capture"
}
```

### `enable-overlay-planes`

Enable direct scanout into overlay planes.
May cause frame drops during some animations on some hardware (which is why it is not the default).

Direct scanout into the primary plane is always enabled.

```kdl
debug {
    enable-overlay-planes
}
```

### `disable-cursor-plane`

Disable the use of the cursor plane.
The cursor will be rendered together with the rest of the frame.

Useful to work around driver bugs on specific hardware.

```kdl
debug {
    disable-cursor-plane
}
```

### `disable-direct-scanout`

Disable direct scanout to both the primary plane and the overlay planes.

```kdl
debug {
    disable-direct-scanout
}
```

### `restrict-primary-scanout-to-matching-format`

Restricts direct scanout to the primary plane to when the window buffer exactly matches the composition swapchain format.

This flag may prevent unexpected bandwidth changes when going between composition and scanout.
The plan is to make it default in the future, when we implement a way to tell the clients the composition swapchain format.
As is, it may prevent some clients (mpv on my machine) from scanning out to the primary plane.

```kdl
debug {
    restrict-primary-scanout-to-matching-format
}
```

### `force-disable-connectors-on-resume`

<sup>Since: 26.04</sup>

Force-disables all outputs upon resuming niri (TTY switch or waking up from suspend).
This causes a modeset/screen blank on all outputs.

If niri rendering is corrupted, or monitors don't light up after a TTY switch, you can try this flag.

```kdl
debug {
    force-disable-connectors-on-resume
}
```

### `render-drm-device`

Override the DRM device that niri will use for all rendering.

You can set this to make niri use a different primary GPU than the default one.

```kdl
debug {
    render-drm-device "/dev/dri/renderD129"
}
```

### `ignore-drm-device`

<sup>Since: 25.11</sup>

List DRM devices that niri will ignore.
Useful for GPU passthrough when you don't want niri to open a certain device.

```kdl
debug {
    ignore-drm-device "/dev/dri/renderD128"
    ignore-drm-device "/dev/dri/renderD130"
}
```

### `force-pipewire-invalid-modifier`

<sup>Since: 25.01</sup>

Forces PipeWire screencasting to use the invalid modifier, even when DRM offers more modifiers.

Useful for testing the invalid modifier code path that is hit by drivers that don't support modifiers.

```kdl
debug {
    force-pipewire-invalid-modifier
}
```

### `dbus-interfaces-in-non-session-instances`

Make niri create its D-Bus interfaces even if it's not running as a `--session`.

Useful for testing screencasting changes without having to relogin.

The main niri instance will *not* currently take back the interfaces when you close the test instance, so you will need to relogin in the end to make screencasting work again.

```kdl
debug {
    dbus-interfaces-in-non-session-instances
}
```

### `wait-for-frame-completion-before-queueing`

Wait until every frame is done rendering before handing it over to DRM.

Useful for diagnosing certain synchronization and performance problems.

```kdl
debug {
    wait-for-frame-completion-before-queueing
}
```

### `emulate-zero-presentation-time`

Emulate zero (unknown) presentation time returned from DRM.

This is a thing on NVIDIA proprietary drivers, so this flag can be used to test that niri doesn't break too hard on those systems.

```kdl
debug {
    emulate-zero-presentation-time
}
```

### `disable-resize-throttling`

<sup>Since: 0.1.9</sup>

Disable throttling resize events sent to windows.

By default, when resizing quickly (e.g. interactively), a window will only receive the next size once it has made a commit for the previously requested size.
This is required for resize transactions to work properly, and it also helps certain clients which don't batch incoming resizes from the compositor.

Disabling resize throttling will send resizes to windows as fast as possible, which is potentially very fast (for example, on a 1000 Hz mouse).

```kdl
debug {
    disable-resize-throttling
}
```

### `disable-transactions`

<sup>Since: 0.1.9</sup>

Disable transactions (resize and close).

By default, windows which must resize together, do resize together.
For example, all windows in a column must resize at the same time to maintain the combined column height equal to the screen height, and to maintain the same window width.

Transactions make niri wait until all windows finish resizing before showing them all on screen in one, synchronized frame.
For them to work properly, resize throttling shouldn't be disabled (with the previous debug flag).

```kdl
debug {
    disable-transactions
}
```

### `keep-laptop-panel-on-when-lid-is-closed`

<sup>Since: 0.1.10</sup>

By default, niri will disable the internal laptop monitor when the laptop lid is closed.
This flag turns off this behavior and will leave the internal laptop monitor on.

```kdl
debug {
    keep-laptop-panel-on-when-lid-is-closed
}
```

### `disable-monitor-names`

<sup>Since: 0.1.10</sup>

Disables the make/model/serial monitor names, as if niri fails to read them from the EDID.

Use this flag to work around a crash present in 0.1.9 and 0.1.10 when connecting two monitors with matching make/model/serial.

```kdl
debug {
    disable-monitor-names
}
```

### `strict-new-window-focus-policy`

<sup>Since: 25.01</sup>

Disables heuristic automatic focusing for new windows.
Only windows that activate themselves with a valid xdg-activation token will be focused.

```kdl
debug {
    strict-new-window-focus-policy
}
```

### `honor-xdg-activation-with-invalid-serial`

<sup>Since: 25.05</sup>

Widely-used clients such as Discord and Telegram make fresh xdg-activation tokens upon clicking on their tray icon or on their notification.
Most of the time, these fresh tokens will have invalid serials, because the app needs to be focused to get a valid serial, and if the user clicks on a tray icon or a notification, it is usually because the app *isn't* focused, and the user wants to focus it.

By default, niri ignores xdg-activation tokens with invalid serials, to prevent windows from randomly stealing focus.
This debug flag makes niri honor such tokens, making the aforementioned widely-used apps get focus when clicking on their tray icon or notification.

Amusingly, clicking on a notification sends the app a perfectly valid activation token from the notification daemon, but these apps seem to simply ignore it.
Maybe in the future these apps/toolkits (Electron, Qt) are fixed, making this debug flag unnecessary.

```kdl
debug {
    honor-xdg-activation-with-invalid-serial
}
```

### `skip-cursor-only-updates-during-vrr`

<sup>Since: 25.08</sup>

Skips redrawing the screen from cursor input while variable refresh rate is active.

Useful for games where the cursor isn't drawn internally to prevent erratic VRR shifts in response to cursor movement.

Note that the current implementation has some issues, for example when there's nothing redrawing the screen (like a game), the rendering will appear to completely freeze (since cursor movements won't cause redraws).

```kdl
debug {
    skip-cursor-only-updates-during-vrr
}
```

### `deactivate-unfocused-windows`

<sup>Since: 25.08</sup>

Some clients (notably, Chromium- and Electron-based, like Teams or Slack) erroneously use the Activated xdg window state instead of keyboard focus for things like deciding whether to send notifications for new messages, or for picking where to show an IME popup.
Niri keeps the Activated state on unfocused workspaces and invisible tabbed windows (to reduce unwanted animations), surfacing bugs in these applications.

Set this debug flag to work around these problems.
It will cause niri to drop the Activated state for all unfocused windows.

```kdl
debug {
    deactivate-unfocused-windows
}
```

### `keep-max-bpc-unchanged`

<sup>Since: 25.08</sup>

When connecting monitors, niri sets their max bpc to 8 in order to reduce display bandwidth and to potentially allow more monitors to be connected at once.
Restricting bpc to 8 is not a problem since we don't support HDR or color management yet and can't really make use of higher bpc.

Apparently, setting max bpc to 8 breaks some displays driven by AMDGPU.
If this happens to you, set this debug flag, which will prevent niri from changing max bpc.
AMDGPU bug report: https://gitlab.freedesktop.org/drm/amd/-/issues/4487.

<sup>Since: 25.11</sup>
This setting is deprecated and does nothing: niri no longer sets max bpc.
The old niri behavior with this setting enabled matches the new behavior.

```kdl
debug {
    keep-max-bpc-unchanged
}
```

### Key Bindings

These are not debug options, but rather key bindings.

#### `toggle-debug-tint`

Tints all surfaces green, unless they are being directly scanned out.

Useful to check if direct scanout is working.

```kdl
binds {
    Mod+Shift+Ctrl+T { toggle-debug-tint; }
}
```

#### `debug-toggle-opaque-regions`

<sup>Since: 0.1.6</sup>

Tints regions marked as opaque with blue and the rest of the render elements with red.

Useful to check how Wayland surfaces and internal render elements mark their parts as opaque, which is a rendering performance optimization.

```kdl
binds {
    Mod+Shift+Ctrl+O { debug-toggle-opaque-regions; }
}
```

#### `debug-toggle-damage`

<sup>Since: 0.1.6</sup>

Tints damaged regions with red.

```kdl
binds {
    Mod+Shift+Ctrl+D { debug-toggle-damage; }
}
```



## Include


<sup>Since: 25.11</sup>

You can include other files at the top level of the config.

```kdl,must-fail
// Some settings...

include "colors.kdl"

// Some more settings...
```

Included files have the same structure as the main config file.
Settings from included files will be merged with the settings from the main config file.

Included config files can in turn include more files.
All included files are watched for changes, and the config live-reloads when any of them change.

You can include by filename or path.

* Relative to the current file: `other.kdl` or `./other.kdl`
* By absolute path: `/path/to/file.kdl`
* <sup>Since: 26.04</sup> Home dir paths: `~/file.kdl` expands to `/home/user/file.kdl`

Includes work only at the top level of the config:

```kdl,must-fail
// All good: include at the top level.
include "something.kdl"

layout {
    // NOT allowed: include inside some other section.
    include "other.kdl"
}
```

### Positionality

Includes are *positional*.
They will override options set *prior* to them.
Window rules from included files will be inserted at the position of the `include` line.
For example:

```kdl
// colors.kdl
layout {
    border {
        active-color "green"
    }
}

overview {
    backdrop-color "green"
}
```

```kdl,must-fail
// config.kdl
layout {
    border {
        active-color "red"
    }
}

// This overrides the border color and the backdrop color to green.
include "colors.kdl"

// This sets the overview backdrop color to red again.
overview {
    backdrop-color "red"
}
```

The end result:

- the border color is green (from `colors.kdl`),
- the overview backdrop color is red (it was set *after* `colors.kdl`).

Another example:

```kdl
// rules.kdl
window-rule {
    match app-id="Alacritty"
    open-maximized false
}
```

```kdl,must-fail
// config.kdl
window-rule {
    open-maximized true
}

// Window rules get inserted at this position.
include "rules.kdl"

window-rule {
    match app-id="firefox$"
    open-maximized true
}
```

This is equivalent to the following config file:

```kdl
window-rule {
    open-maximized true
}

// Included from rules.kdl.
window-rule {
    match app-id="Alacritty"
    open-maximized false
}

window-rule {
    match app-id="firefox$"
    open-maximized true
}
```

### Optional includes

<sup>Since: 26.04</sup>

By default, including a nonexistent file will cause an error.
You can allow nonexistent includes by setting `optional=true`:

```kdl,must-fail
// Won't fail if this file doesn't exist.
include optional=true "optional-config.kdl"

// Regular include, will fail if the file doesn't exist.
include "required-config.kdl"
```

When an optional include file is missing, niri will emit a warning in the logs on every config reload.
This reminds you that the file is missing while still loading the config successfully.

The optional file is still watched for changes, so if you create it later, the config will automatically reload and apply the new settings.

Note that `optional` only affects whether a missing file causes an error.
If the file exists but contains invalid syntax or other errors, those errors will still cause a parsing failure.


### Merging

Most config sections are merged between includes, meaning that you can set only a few properties, and only those properties will change.

```kdl
// colors.kdl
layout {
    // Does not affect gaps, border width, etc.
    // Only changes colors as written.
    focus-ring {
        active-color "blue"
    }

    border {
        active-color "green"
    }
}
```

```kdl,must-fail
// config.kdl
include "colors.kdl"

layout {
    // Does not set border and focus-ring colors,
    // so colors from colors.kdl are used.
    gaps 8

    border {
        width 8
    }
}
```

#### Multipart sections

Multipart sections like `window-rule`, `output`, or `workspace` are inserted as is without merging:

```kdl
// laptop.kdl
output "eDP-1" {
    // ...
}
```

```kdl,must-fail
// config.kdl
output "DP-2" {
    // ...
}

include "laptop.kdl"

// End result: both DP-2 and eDP-1 settings.
```

#### Binds

`binds` will override previously-defined conflicting keys:

```kdl
// binds.kdl
binds {
    Mod+T { spawn "alacritty"; }
}
```

```kdl,must-fail
// config.kdl
include "binds.kdl"

binds {
    // Overrides Mod+T from binds.kdl.
    Mod+T { spawn "foot"; }
}
```

#### Flags

Most flags can be disabled with `false`:

```kdl
// csd.kdl

// Write "false" to explicitly disable.
prefer-no-csd false
```

```kdl,must-fail
// config.kdl

// Enable prefer-no-csd in the main config.
prefer-no-csd

// Including csd.kdl will disable it again.
include "csd.kdl"
```

#### Non-merging sections

Some sections where the contents represent a combined structure are not merged.
Examples are `struts`, `preset-column-widths`, individual subsections in `animations`, pointing device sections in `input`.

```kdl
// struts.kdl
layout {
    struts {
        left 64
        right 64
    }
}
```

```kdl,must-fail
// config.kdl
layout {
    struts {
        top 64
        bottom 64
    }
}

include "struts.kdl"

// Struts are not merged.
// End result is only left and right struts.
```

### Border special case

There's one special case that differs between the main config and included configs.

Writing `layout { border {} }` in an included config does nothing (since no properties are changed).
However, writing the same in the main config will *enable* the border, i.e. it's equivalent to `layout { border { on; } }`.

So, if you want to move your layout configuration from the main config to a separate file, remember to add `on` to the border section, for example:

```kdl
// separate.kdl
layout {
    border {
        // Add this line:
        on

        width 4
        active-color "#ffc87f"
        inactive-color "#505050"
    }
}
```

The reason for this special case is that this is how it historically worked: back when I added borders, we didn't have any `on` flags, so I made writing the `border {}` section enable the border, with an explicit `off` to disable it.
It wouldn't be too problematic to change it, however the default config always had a pre-filled `layout { border { off; } }` section with a note saying that commenting out the `off` is enough to enable the border.
Many people likely have this part of the default config embedded in their configs now, so changing how it works would just cause a lot of confusion.



---

Source: niri 26.04 documentation (`share/doc/niri/default-config.kdl` and `share/doc/niri/wiki/Configuration:-*.md`).
Regenerate with:

```sh
niri-doc=$(find /nix/store -maxdepth 1 -type d -name '*-niri-26.04-doc' | head -1)
echo "$niri-doc/share/doc/niri"
```
