# Migration: Vanilla GNOME → Hyprland + Quickshell UI

Reference project: `/home/dominic/Desktop/nixos-configuration`

**Starting point**: Vanilla GNOME on NixOS (Hyprland modules exist in the repo but are not enabled).

**Goal**: Enable Hyprland and layer on the Quickshell bar/popup UI from the reference project.

> **Note**: The reference project lists EWW as a module but it is legacy. The active, polished UI is **Quickshell** (Qt6/QML). That is what this doc covers.

---

## Step 1: Enable Hyprland (system + home-manager)

Both modules already exist in the repo — they just need to be wired in.

### `hosts/nixos/default.nix`

Replace the GNOME block with the Hyprland nixos module:

```nix
# Remove:
services.xserver.enable = true;
services.xserver.desktopManager.gnome.enable = true;
services.displayManager.gdm.enable = true;

# Add:
"${nixosModules}/desktop/hyprland"
# (add to imports list)
```

### `home/dominic/nixos/default.nix`

Add the Hyprland home-manager module to imports:

```nix
"${nhModules}/desktop/hyprland"
```

This enables Hyprland via UWSM, sets it as the default session, and symlinks `hyprland.conf` from `modules/home-manager/desktop/hyprland/hyprland.conf`.

### Rebuild

```bash
sudo nixos-rebuild switch --flake .#nixos
```

At this point you have a working Hyprland desktop with the existing config (no animations, Albert launcher, Noctalia Shell bar).

---

## Step 2: Add the Quickshell Bar

The reference project replaces the Noctalia bar with **Quickshell** (Qt6/QML) — a persistent top bar with animated workspace pills, media player, weather, system pills, and a morphing popup system.

### 2a. Add packages to the nixos system module or home packages

```nix
environment.systemPackages = with pkgs; [
  quickshell
  swww          # wallpaper daemon
  swaync        # notification center
  swayosd       # volume/brightness OSD
  playerctl
  playerctld
  wl-clipboard
];
```

### 2b. Copy Quickshell QML files

Copy the entire `nixos-configuration/config/sessions/hyprland/quickshell/` directory into this repo:

```
files/configs/quickshell/
```

### 2c. Create a Quickshell home-manager module

Create `modules/home-manager/programs/quickshell/default.nix` that:
- Symlinks `files/configs/quickshell/` via `xdg.configFile`
- Starts the two Quickshell services on login

### 2d. Import the new module

In `home/dominic/nixos/default.nix`, add:

```nix
"${nhModules}/programs/quickshell"
```

### 2e. Disable Noctalia

In `home/dominic/nixos/default.nix` (or `common.nix`), remove or comment out:

```nix
"${nhModules}/programs/noctalia"
```

Also remove the `noctalia` flake input from `flake.nix` if nothing else uses it.

---

## Step 3: Add Supporting Scripts

Copy from `nixos-configuration/config/sessions/hyprland/scripts/` to `files/scripts/`:

| Script | Purpose |
|---|---|
| `qs_manager.sh` | Manages popup state via `/tmp/qs_widget_state` IPC |
| `sys_info.sh` | Feeds battery, wifi, volume, keyboard layout to bar |
| `music_info.sh` | Feeds media metadata (title, artist, album art) to bar |
| `weather.sh` | Weather data for bar center widget |
| `rofi_show.sh` | Launcher/window-switcher wrapper for Rofi |

These need to be executable and installed to `~/.local/bin` via the existing scripts module pattern.

---

## Step 4: Update Hyprland Config

Edit `modules/home-manager/desktop/hyprland/hyprland.conf`:

### Enable animations

```ini
animations {
  enabled = true
  bezier = myBezier, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 5, myBezier, popin 80%
  animation = layers, 1, 5, default, fade
  animation = workspaces, 1, 5, default, slide
  animation = specialWorkspace, 1, 5, default, fade
}
```

### Update keybindings

```ini
# Replace Albert with Rofi
bind = $mainMod, D, exec, rofi_show.sh drun         # app launcher
bind = ALT, Tab, exec, rofi_show.sh window           # window switcher
bind = $mainMod, C, exec, rofi_show.sh clipboard     # clipboard history

# Remove Albert bindings (Ctrl+Space, Super+A for Albert)

# Add Quickshell popup bindings (via qs_manager.sh)
bind = $mainMod, Q, exec, qs_manager.sh toggle music
bind = $mainMod, B, exec, qs_manager.sh toggle battery
bind = $mainMod, W, exec, qs_manager.sh toggle wallpaper
bind = $mainMod, S, exec, qs_manager.sh toggle calendar
bind = $mainMod, N, exec, qs_manager.sh toggle network
bind = $mainMod SHIFT, S, exec, qs_manager.sh toggle stewart

# Media
bind = $mainMod, Space, exec, playerctl play-pause

# Notifications (swaync replaces Noctalia notifications)
bind = $mainMod, A, exec, swaync-client -t
```

### Add window rules for the Quickshell popup container

```ini
windowrule = float, class:qs-master
windowrule = pin, class:qs-master
windowrule = noborder, class:qs-master
windowrule = noshadow, class:qs-master
```

### Add autostart entries

```ini
exec-once = swww-daemon
exec-once = swaync
exec-once = swayosd-server
exec-once = playerctld
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = quickshell -c ~/.config/quickshell/TopBar.qml
exec-once = quickshell -c ~/.config/quickshell/Main.qml
```

---

## Step 5: Update Lock Screen Config

Copy `nixos-configuration/config/sessions/hyprland/hyprlock.conf` to `files/configs/hypr/hyprlock.conf` and add a symlink in the Hyprland home-manager module:

```nix
xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
```

The reference hyprlock config gives you:
- Blurred screenshot background
- 120px time display (JetBrains Mono ExtraBold)
- 18px date
- Pill-shaped input field with mauve border
- Bottom dock with user/layout/battery info

---

## Step 6: Add Iosevka Nerd Font

The Quickshell bar uses Iosevka Nerd Font for icons. Add to your font packages:

```nix
fonts.packages = with pkgs; [
  nerd-fonts.iosevka
];
```

---

## Step 7: Final Rebuild

```bash
sudo nixos-rebuild switch --flake .#nixos
```

---

## Full Migration Order (summary)

1. **Enable Hyprland** — uncomment/add imports in `hosts/nixos/default.nix` and `home/dominic/nixos/default.nix`
2. **Rebuild** to confirm Hyprland works before adding the bar
3. **Add packages** — quickshell, swww, swaync, swayosd, playerctl, Iosevka Nerd Font
4. **Copy Quickshell QML files** → `files/configs/quickshell/`
5. **Copy scripts** → `files/scripts/`
6. **Create Quickshell home-manager module**
7. **Update hyprland.conf** — animations, keybindings, window rules, autostart
8. **Update hyprlock.conf**
9. **Disable Noctalia**
10. **Final rebuild** `sudo nixos-rebuild switch --flake .#nixos`

---

## User-Facing Experience (end state)

### Top Bar
A persistent 48px bar at the top with three zones:

**Left:** Search icon → Rofi | Notifications bell | Animated workspace pills (active=mauve, occupied=blue, empty=dimmed) | Media player (slides in when music plays: album art + title + controls)

**Center:** Live clock (HH:mm:ss) with scrollable date | Weather icon + temperature

**Right:** Keyboard layout | WiFi SSID | Bluetooth device | Volume % | Battery % | System tray — all as clickable pills

### Popup Widgets

| Keybind | Popup |
|---|---|
| `Super+Q` | Music player — EQ visualizer, album art, device selector |
| `Super+B` | Battery details |
| `Super+W` | Wallpaper picker |
| `Super+S` | Calendar |
| `Super+N` | Network |
| `Super+Shift+S` | Stewart launcher |
| `Escape` | Close any popup |

All popups share one floating window and morph between each other with 350ms animations.

### Window & Workspace Navigation

| Keybind | Action |
|---|---|
| `Super+1-9,0` | Switch workspace |
| `Super+Shift+1-9,0` | Move window to workspace |
| `Super+hjkl` or `Super+Arrows` | Move focus |
| `Super+Shift+Arrows` | Resize window |
| `Super+Shift+F` | Toggle float |
| `Super+M` | Toggle fullscreen |
| `Super+Q` | Close window (also opens music popup — you may want to remap one) |
| `Super+LMB drag` | Move window |
| `Super+RMB drag` | Resize window |
| `Super+Scroll` | Cycle workspaces |

### Other

| Keybind | Action |
|---|---|
| `Super+D` | App launcher (Rofi) |
| `Alt+Tab` | Window switcher (Rofi) |
| `Super+C` | Clipboard history |
| `Super+Space` | Play/Pause media |
| `Super+A` | Toggle notification center (swaync) |
| `Ctrl+Alt+L` | Lock screen |
| `Print` | Area screenshot → swappy editor |
| `Shift+Print` | Full screen screenshot with editor |
| Brightness/Volume fn keys | swayosd OSD overlay |

---

## Color Reference (Catppuccin Mocha — no changes needed)

Both projects use Catppuccin Mocha so no theme changes are required.

| Name | Hex | Used for |
|---|---|---|
| Mauve | `#cba6f7` | Active workspace, highlighted elements |
| Blue | `#89b4fa` | Actions, WiFi |
| Sapphire | `#74c7ec` | Media info |
| Lavender | `#b4befe` | Alternatives (current border color) |
| Peach | `#fab387` | Volume |
| Red | `#f38ba8` | Low battery, critical |
| Green | `#a6e3a1` | Good battery |
| Subtext0 | `#a6adc8` | Secondary text, inactive items |
