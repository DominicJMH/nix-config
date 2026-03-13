Plan to implement │
│ │
│ Migration Plan: Vanilla GNOME → Hyprland + Quickshell UI │
│ │
│ Context │
│ │
│ Current state is vanilla GNOME on NixOS (Hyprland modules exist in the repo but are commented out / not imported). Goal is to enable Hyprland and layer the │
│ Quickshell bar + popup UI from the reference project at /home/dominic/Desktop/nixos-configuration. │
│ │
│ User preference: Re-enable Alacritty (not Kitty), keep Super+Q for close window (music popup → Super+Shift+M). │
│ │
│ Dry-run command: sudo nixos-rebuild dry-activate --flake .#nixos │
│ │
│ --- │
│ Critical File Paths │
│ │
│ Modified │
│ │
│ - hosts/nixos/default.nix │
│ - home/dominic/nixos/default.nix │
│ - modules/home-manager/desktop/wayland-common/default.nix │
│ - modules/home-manager/desktop/hyprland/default.nix │
│ - modules/home-manager/desktop/hyprland/hyprland.conf │
│ - modules/nixos/desktop/wayland-common/default.nix │
│ │
│ New │
│ │
│ - modules/home-manager/programs/quickshell/default.nix │
│ - modules/home-manager/programs/quickshell/scripts/ (all QML + scripts from reference) │
│ - modules/home-manager/programs/rofi/default.nix │
│ - modules/home-manager/programs/rofi/config/ (rofi configs from reference) │
│ - modules/home-manager/desktop/hyprland/hyprlock.conf │
│ - modules/home-manager/desktop/hyprland/hyprlock/scripts/battery.sh │
│ - modules/home-manager/desktop/hyprland/hyprlock/scripts/layout.sh │
│ │
│ --- │
│ Step 1 — Enable Hyprland System-Level │
│ │
│ hosts/nixos/default.nix: Remove GNOME block, add Hyprland nixos module. │
│ │
│ # Remove these 3 lines: │
│ services.xserver.enable = true; │
│ services.xserver.desktopManager.gnome.enable = true; │
│ services.displayManager.gdm.enable = true; │
│ │
│ # Add to imports: │
│ "${nixosModules}/desktop/hyprland"                                                                                                                          │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 2 — Enable Hyprland + Quickshell + Rofi Home-Manager                                                                                                   │
│                                                                                                                                                             │
│ home/dominic/nixos/default.nix:                                                                                                                             │
│ - Add "${nhModules}/desktop/hyprland" to imports │
│ - Add "${nhModules}/programs/quickshell" to imports                                                                                                         │
│ - Add "${nhModules}/programs/rofi" to imports │
│ - Change programs.alacritty.enable = lib.mkForce false; → programs.alacritty.enable = true; │
│ │
│ --- │
│ Step 3 — Remove Noctalia │
│ │
│ modules/home-manager/desktop/wayland-common/default.nix: Remove the "${nhModules}/programs/noctalia" import line.                                           │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 4 — Add System Packages + SwayOSD                                                                                                                      │
│                                                                                                                                                             │
│ modules/nixos/desktop/wayland-common/default.nix: Add programs.swayosd.enable = true; and add to system packages: swaynotificationcenter, brightnessctl,    │
│ playerctl, wl-clipboard, cliphist, jq, ffmpeg, imagemagick, rofi-wayland, swww.                                                                             │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 5 — Copy Quickshell Files from Reference                                                                                                               │
│                                                                                                                                                             │
│ Structure to create (symlinked to ~/.config/hypr/scripts/):                                                                                                 │
│ modules/home-manager/programs/quickshell/scripts/                                                                                                           │
│ ├── qs_manager.sh                                                                                                                                           │
│ ├── rofi_show.sh                                                                                                                                            │
│ ├── rofi_clipboard.sh                                                                                                                                       │
│ ├── screenshot.sh                                                                                                                                           │
│ ├── volume_listener.sh                                                                                                                                      │
│ ├── volume.sh                                                                                                                                               │
│ ├── bluetooth_mgr.sh                                                                                                                                        │
│ └── quickshell/                                                                                                                                             │
│     ├── Main.qml                                                                                                                                            │
│     ├── TopBar.qml                                                                                                                                          │
│     ├── sys_info.sh                                                                                                                                         │
│     ├── workspaces.sh                                                                                                                                       │
│     ├── DataSource.qml     ← from programs/quickshell/                                                                                                      │
│     ├── Style.qml          ← from programs/quickshell/                                                                                                      │
│     ├── qmldir             ← from programs/quickshell/                                                                                                      │
│     ├── bar/               ← from programs/quickshell/                                                                                                      │
│     ├── images/            ← from programs/quickshell/                                                                                                      │
│     ├── battery/                                                                                                                                            │
│     ├── calendar/                                                                                                                                           │
│     ├── music/                                                                                                                                              │
│     ├── network/                                                                                                                                            │
│     ├── stewart/                                                                                                                                            │
│     └── wallpaper/                                                                                                                                          │
│                                                                                                                                                             │
│ Copy sources:                                                                                                                                               │
│ - nixos-configuration/config/sessions/hyprland/scripts/ → top-level scripts + quickshell/ subdirectory                                                      │
│ - nixos-configuration/config/programs/quickshell/{DataSource.qml,Style.qml,qmldir,bar/,images/} → merged into quickshell/ subdirectory                      │
│                                                                                                                                                             │
│ modules/home-manager/programs/quickshell/default.nix:                                                                                                       │
│ { pkgs, ... }:                                                                                                                                              │
│ {                                                                                                                                                           │
│   home.packages = with pkgs; [ swww playerctl wl-clipboard cliphist jq ffmpeg imagemagick ];                                                                │
│                                                                                                                                                             │
│   xdg.configFile."hypr/scripts" = {                                                                                                                         │
│     source = ./scripts;                                                                                                                                     │
│     recursive = true;                                                                                                                                       │
│   };                                                                                                                                                        │
│ }                                                                                                                                                           │
│                                                                                                                                                             │
│ Note: source = ./scripts creates a Nix store symlink preserving the directory tree. Scripts must have executable bits set on copy.                          │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 6 — Copy Rofi Config Files                                                                                                                             │
│                                                                                                                                                             │
│ Copy from nixos-configuration/config/programs/rofi/:                                                                                                        │
│ modules/home-manager/programs/rofi/config/                                                                                                                  │
│ ├── config.rasi                                                                                                                                             │
│ ├── theme.rasi                                                                                                                                              │
│ ├── quicklink.yaml                                                                                                                                          │
│ └── quick-icons/                                                                                                                                            │
│     ├── copy.png                                                                                                                                            │
│     ├── kill.png                                                                                                                                            │
│     ├── onenote.png                                                                                                                                         │
│     └── youtube.png                                                                                                                                         │
│                                                                                                                                                             │
│ modules/home-manager/programs/rofi/default.nix:                                                                                                             │
│ { pkgs, ... }:                                                                                                                                              │
│ {                                                                                                                                                           │
│   home.packages = [ pkgs.rofi-wayland ];                                                                                                                    │
│                                                                                                                                                             │
│   xdg.configFile."rofi" = {                                                                                                                                 │
│     source = ./config;                                                                                                                                      │
│     recursive = true;                                                                                                                                       │
│   };                                                                                                                                                        │
│ }                                                                                                                                                           │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 7 — Copy Hyprlock Config + Scripts                                                                                                                     │
│                                                                                                                                                             │
│ Copy from nixos-configuration/config/sessions/hyprland/hyprlock/:                                                                                           │
│ - hyprlock.conf → modules/home-manager/desktop/hyprland/hyprlock.conf                                                                                       │
│ - scripts/battery.sh → modules/home-manager/desktop/hyprland/hyprlock/scripts/battery.sh                                                                    │
│ - scripts/layout.sh → modules/home-manager/desktop/hyprland/hyprlock/scripts/layout.sh                                                                      │
│                                                                                                                                                             │
│ modules/home-manager/desktop/hyprland/default.nix: Add symlinks:                                                                                            │
│ xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;                                                                                               │
│ xdg.configFile."hypr/hyprlock/scripts" = {                                                                                                                  │
│   source = ./hyprlock/scripts;                                                                                                                              │
│   recursive = true;                                                                                                                                         │
│ };                                                                                                                                                          │
│                                                                                                                                                             │
│ ---                                                                                                                                                         │
│ Step 8 — Update hyprland.conf                                                                                                                               │
│                                                                                                                                                             │
│ modules/home-manager/desktop/hyprland/hyprland.conf changes:                                                                                                │
│                                                                                                                                                             │
│ Enable animations (replace enabled = false block):                                                                                                          │
│                                                                                                                                                             │
│ animations {                                                                                                                                                │
│     enabled = true                                                                                                                                          │
│     bezier = myBezier, 0.05, 0.9, 0.1, 1.05                                                                                                                 │
│     animation = windows, 1, 5, myBezier, popin 80%                                                                                                          │
│     animation = layers, 1, 5, default, fade                                                                                                                 │
│     animation = workspaces, 1, 5, default, slide                                                                                                            │
│     animation = specialWorkspace, 1, 5, default, fade                                                                                                       │
│ }                                                                                                                                                           │
│                                                                                                                                                             │
│ Add exec-once autostart (after misc block):                                                                                                                 │
│                                                                                                                                                             │
│ exec-once = swww-daemon                                                                                                                                     │
│ exec-once = swaync                                                                                                                                          │
│ exec-once = swayosd-server                                                                                                                                  │
│ exec-once = playerctld                                                                                                                                      │
│ exec-once = wl-paste --type text --watch cliphist store                                                                                                     │
│ exec-once = wl-paste --type image --watch cliphist store                                                                                                    │
│ exec-once = ~/.config/hypr/scripts/volume_listener.sh                                                                                                       │
│ exec-once = quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml                                                                                      │
│ exec-once = quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml                                                                                        │
│                                                                                                                                                             │
│ Add qs-master window rules (after existing windowrules):                                                                                                    │
│                                                                                                                                                             │
│ windowrule = match:class ^(qs-master)$, float on, pin on, border_size 0, noshadow │
│ │
│ Replace all noctalia/albert bindings: │
│ │
│ # Remove: Albert bindings (Super+A, Ctrl+Space) │
│ # Remove: All noctalia-shell ipc calls │
│ │
│ # Add app launcher (Rofi) │
│ bind = $mainMod, D, exec, ~/.config/hypr/scripts/rofi_show.sh drun │
│ bind = ALT, Tab, exec, ~/.config/hypr/scripts/rofi_show.sh window │
│ bind = $mainMod, C, exec, ~/.config/hypr/scripts/rofi_clipboard.sh │
│ │
│ # Add Quickshell popups │
│ bind = $mainMod SHIFT, M, exec, ~/.config/hypr/scripts/qs_manager.sh toggle music │
│ bind = $mainMod, B, exec, ~/.config/hypr/scripts/qs_manager.sh toggle battery │
│ bind = $mainMod, W, exec, ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper │
│ bind = $mainMod, S, exec, ~/.config/hypr/scripts/qs_manager.sh toggle calendar │
│ bind = $mainMod, N, exec, ~/.config/hypr/scripts/qs_manager.sh toggle network │
│ │
│ # Notifications (swaync) │
│ bind = $mainMod, A, exec, swaync-client -t │
│ bind = $mainMod SHIFT, Backspace, exec, swaync-client -C │
│ │
│ # Lock screen (hyprlock) │
│ bind = CTRL ALT, L, exec, hyprlock │
│ │
│ # Media │
│ bind = $mainMod, Space, exec, playerctl play-pause │
│ │
│ # Volume/brightness via swayosd │
│ bind = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise │
│ bind = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower │
│ bind = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle │
│ bind = , XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle │
│ bind = , XF86MonBrightnessUp, exec, swayosd-client --brightness raise │
│ bind = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower │
│ │
│ # Screenshot (keep existing grimblast binds) │
│ │
│ Note: existing Super+M (fullscreen) conflicts with Super+Shift+M (music popup) is fine — different mod combos. │
│ Note: existing Super+N now opens network popup instead of Noctalia notifications; notifications are Super+A. │
│ │
│ --- │
│ Step 9 — Add Iosevka Nerd Font │
│ │
│ modules/nixos/desktop/hyprland/default.nix: Add font: │
│ fonts.packages = [ pkgs.nerd-fonts.iosevka ]; │
│ │
│ --- │
│ Verification (Dry-Run) │
│ │
│ cd /home/dominic/Desktop/nix-config │
│ sudo nixos-rebuild dry-activate --flake .#nixos │
│ │
│ This tests Nix expression evaluation and package resolution without activating. Success means the migration is valid at the Nix level. QML and script │
│ runtime behavior is tested on actual activation.
