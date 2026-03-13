# Desktop Services & Theming

This document covers the desktop shell (Noctalia), idle/lock management (Hypridle), display layout management (Kanshi), and the theming plumbing for GTK, Qt, and XDG.

---

## 1. Noctalia

### What it is

Noctalia is a **desktop shell** — a complete layer of UI that sits on top of a Wayland compositor and provides all the visual chrome that makes a desktop actually usable: a top bar, notification system, control centre panel, lock screen, app launcher, clipboard manager, wallpaper engine, and more. It is compositor-agnostic, meaning it works identically on both Hyprland and Niri.

Think of it as the equivalent of GNOME Shell or KDE Plasma, but designed specifically for tiling Wayland setups. While Hyprland and Niri handle *window management*, Noctalia handles *everything else you see on the desktop*.

Noctalia communicates with the running session through an IPC interface. You'll see `noctalia-shell ipc call ...` throughout the Hyprland and Niri keybindings — this is how key presses trigger Noctalia actions (lock screen, volume, brightness, notifications, etc.).

### In this project

**File:** `modules/home-manager/programs/noctalia/default.nix`

Noctalia is loaded from the `inputs.noctalia` flake input and runs as a **systemd user service** (`systemd.enable = true`), auto-starting with the graphical session.

#### Colour Integration

Rather than hardcoding colours, the config reads the Catppuccin palette JSON directly at evaluation time and maps palette roles to Noctalia's Material You-style colour system:

| Noctalia Role | Catppuccin Colour |
|---|---|
| `mPrimary` | Accent (lavender) |
| `mOnPrimary` | Crust (darkest background — text on accent) |
| `mSecondary` | Pink |
| `mTertiary` | Mauve |
| `mError` | Red |
| `mSurface` | Base (main background) |
| `mOnSurface` | Text |
| `mSurfaceVariant` | Surface0 (slightly lighter panel background) |
| `mOutline` | Overlay0 (borders) |
| `mShadow` | Crust |

This means every Noctalia panel, notification, and widget automatically uses the correct Catppuccin shade.

#### Top Bar

The bar sits at the **top of the screen**, always visible, with 93% background opacity and a 12px frame radius. No floating bar. Layout:

**Left:**
- `Workspace` widget — shows numbered workspace indicators; hides unoccupied workspaces, highlights focused one in lavender (primary), occupied in pink (secondary)

**Centre:**
- `Clock` — shows `HH:mm ddd, MMM dd` (e.g. `14:32 Thu, Mar 12`)
- `NotificationHistory` — bell icon with unread badge; click to open notification history panel

**Right:**
- `Tray` — system tray with drawer for overflow icons
- `KeyboardLayout` — always visible; shows current layout (PL/RU toggle)
- `Network` — shows on hover
- `Volume` — shows on hover
- `Battery` — graphic display, hidden if not detected (so it disappears on a desktop)
- `plugin:screen-recorder` — recording indicator, hidden when inactive
- `plugin:privacy-indicator` — mic/camera in-use indicator, shown in red (`error` colour) when active, hidden otherwise

#### Control Centre

Opened with `Super+C`. A slide-out panel containing:
- **Profile card** — user avatar and name (pulled from `userConfig.avatar`)
- **Shortcuts card** — quick toggles for Network, Bluetooth, Notifications (left), and Power Profile, Noctalia Performance, Airplane Mode (right)
- **Brightness card** — slider
- Disabled: weather card, audio card, media monitor

Brightness step is 5% per keypress. DDC support (for external monitors) is off.

#### Notifications

- Location: top-right
- Low urgency: 3 seconds
- Normal urgency: 7 seconds
- Critical urgency: 15 seconds
- All urgency levels saved to history
- No notification sounds
- Compact density

#### Lock Screen

- Triggered by `Ctrl+Alt+L` or on suspend
- Compact style, custom clock format (`hh\nmm` — stacked hours and minutes)
- 10-second countdown timer before locking
- Blur: none, tint: none (clean, sharp)
- Animations: disabled
- Shows session buttons (lock/suspend/shutdown etc.)

Internal keybinds inside Noctalia panels use vim-style navigation: `Ctrl+H/J/K/L` for left/down/up/right.

#### Wallpaper

- Managed by Noctalia, loaded from a `wallpapers.json` cache file that points to `userConfig.wallpaper`
- Fill mode: crop
- Set on all monitors simultaneously
- No transitions (instant change, `transitionDuration = 0`)
- Overview blur: 40%, tint: 60% (wallpaper is visible but dimmed when switching workspaces)

#### Plugins

Two official plugins from the Noctalia plugin repository are enabled:

**`screen-recorder`**
- Format: H.264 video, Opus audio (no audio by default — `audioSource = "none"`)
- Quality: very high, 60 fps
- Uses the Wayland `portal` screen capture API (privacy-safe, user-approved)
- Toggled via `Super+Shift+R`
- Indicator hidden when not recording

**`privacy-indicator`**
- Watches for microphone and camera activity
- Shows a red dot in the bar when a mic or camera is live
- Hidden when nothing is active (`hideInactive = true`)
- Toast notifications disabled (silent)

#### Night Light

- Auto-schedule based on sunrise/sunset
- Day colour temperature: 6500K (neutral white)
- Night colour temperature: 4000K (warm amber)
- Fallback manual times: 06:30 sunrise, 18:30 sunset

---

## 2. Hypridle

### What it is

Hypridle is an **idle daemon** for Hyprland and other Wayland compositors. It watches for user inactivity (no keyboard or mouse input) and runs commands after configurable timeout periods — typically to dim the screen, turn off the display, lock the session, or suspend the machine.

Without an idle daemon, your screen would stay on forever regardless of inactivity. Hypridle is the bridge between "nothing happened for N minutes" and "do something about it."

It runs as a **systemd user service** alongside the compositor.

### In this project

**File:** `modules/home-manager/services/hypridle/default.nix`

The config is intentionally minimal — only three hooks are set:

```nix
before_sleep_cmd = "noctalia-shell ipc call lockScreen lock";
after_sleep_cmd  = "pidof Hyprland >/dev/null && hyprctl dispatch dpms on
                    || niri msg action power-on-monitors";
lock_cmd         = "noctalia-shell ipc call lockScreen lock";
```

**`before_sleep_cmd`** — runs *immediately before* the system suspends. This locks the Noctalia lock screen so that when the machine wakes up, you're presented with a password prompt rather than your open desktop.

**`after_sleep_cmd`** — runs *after waking from suspend*. It checks which compositor is running:
- If Hyprland is active (`pidof Hyprland` succeeds) → uses `hyprctl dispatch dpms on` to re-enable the display
- Otherwise (Niri) → uses `niri msg action power-on-monitors`

This dual-compositor check is what makes the config work transparently on both Hyprland and Niri without separate modules.

**`lock_cmd`** — the command Hypridle calls if it receives an external "lock now" signal (e.g. from `loginctl lock-session` or Albert's system plugin).

Note: Noctalia has its own built-in idle manager (`settings.idle`), but it is **disabled** (`enabled = false`) in this config — Hypridle handles idle locking instead, keeping concerns separated.

---

## 3. Kanshi

### What it is

Kanshi is a **dynamic display configuration daemon** for Wayland. It automatically applies different monitor layouts depending on which displays are physically connected.

The problem it solves: when you dock a laptop, you typically want the external monitor to be the primary display and the laptop screen to turn off (or be positioned correctly beside the external). When you undock, you want the laptop screen to re-enable at full scale. Without Kanshi (or equivalent), you'd need to manually run `wlr-randr` or similar commands every time you connect/disconnect a display.

Kanshi watches for display connection events and matches the current set of connected outputs against its profiles, applying the matching profile automatically.

### In this project

**File:** `modules/home-manager/services/kanshi/default.nix`

Two profiles are defined, targeting the **ThinkPad Z13** (`nabokikh-z13`), which has a built-in HiDPI display (`eDP-1`):

#### Profile: `docked`

Triggered when *any external display* is connected alongside `eDP-1`.

```
External monitor (*): position 0,0, scale 1.0, enabled
eDP-1 (laptop screen): disabled
```

- The external monitor takes over at native (1×) scale
- The laptop screen is turned off — no duplicate display, no awkward secondary screen beneath a desk
- The wildcard `*` matches any external monitor by identity

#### Profile: `undocked`

Triggered when only `eDP-1` is available (no external display).

```
eDP-1: position 0,0, enabled
```

- The laptop screen re-enables at its own scale settings
- No external monitor configuration

Kanshi starts as part of the `graphical-session.target`, so it's active from the moment the compositor starts.

---

## 4. GTK Theming

### What it is

GTK (GIMP Toolkit) is the UI toolkit used by most Linux desktop applications — Nautilus (file manager), GNOME apps, Firefox, Telegram (desktop), and many others. GTK has a theming system where you can supply a CSS-based theme that controls colours, borders, button shapes, and widget styles across all GTK apps uniformly.

There are two active generations: **GTK3** (older) and **GTK4** (current). Both need to be configured.

### In this project

**File:** `modules/home-manager/misc/gtk/default.nix`

| Setting | Value |
|---|---|
| Colour scheme | Dark |
| GTK theme | `catppuccin-mocha-lavender-compact` |
| Icon theme | `Tela-circle-dark` |
| Cursor theme | `Yaru`, size 24 |
| Font | Roboto 11pt |

**Theme** — The Catppuccin GTK theme package is built dynamically using the global flavor (`mocha`) and accent (`lavender`) from the Catppuccin config, so changing the accent in `common/default.nix` automatically rebuilds the GTK theme. The `compact` size variant reduces padding slightly for a denser layout.

**Icon theme** — `Tela-circle-dark` provides a consistent set of circular app icons. It replaces the default GNOME/Adwaita icons for a more polished, unified look.

**Cursor** — `Yaru` is Ubuntu's cursor theme; clean, clearly visible, not too large.

**GTK3 Bookmarks** — The file manager sidebar is pre-populated with shortcuts to:
- `~/Documents`
- `~/Downloads`
- `~/Pictures`
- `~/Videos`
- `~/Downloads/temp`
- `~/Documents/repositories`

**GTK4** — explicitly set to the same theme as GTK3 (`gtk4.theme = config.gtk.theme`), ensuring visual consistency between GTK3 and GTK4 apps.

The cursor theme configured here is also propagated to the Wayland pointer cursor (in `wayland-common`) so the cursor looks the same in both X11-compatibility mode and native Wayland apps.

---

## 5. Qt Theming

### What it is

Qt is the other major Linux UI toolkit, used by KDE applications, Anki, VLC, and others. GTK and Qt are completely separate systems — a GTK theme has no effect on Qt apps and vice versa. To make Qt apps look consistent with the rest of the desktop, Qt needs its own theming layer.

The Qt theming stack in use here involves two tools:
- **qt6ct** — a Qt settings tool that lets you configure fonts, icon themes, and style engine without KDE
- **Kvantum** — a Qt style engine that renders Qt widgets using SVG-based themes (including a Catppuccin theme)

### In this project

**File:** `modules/home-manager/misc/qt/default.nix`

```nix
qt.platformTheme.name = "qtct";    # Use qt6ct for settings
qt.style.name = "kvantum";         # Use Kvantum as the style engine
catppuccin.kvantum.enable = true;  # Apply Catppuccin Kvantum theme
```

- **qt6ct** is set as the platform theme, which means Qt reads its settings (font, icons, style) from the qt6ct config rather than trying to detect KDE or GTK
- The icon theme is synced to the GTK icon theme (`config.gtk.iconTheme.name` = `Tela-circle-dark`) so Qt and GTK apps show the same icons
- **Kvantum** is the rendering engine: it applies a full Catppuccin SVG theme to all Qt widgets — buttons, menus, sliders, scroll bars — matching the mocha palette

The result: Qt apps (Anki, VLC, etc.) render with the same dark Catppuccin colours as GTK apps, without needing KDE installed.

---

## 6. XDG

### What it is

XDG (Cross-Desktop Group) is a set of standards that define how Linux desktop applications find and store files, declare their capabilities, and open content. There are several relevant pieces:

- **XDG Base Directories** — standard paths like `~/.config`, `~/.cache`, `~/.local/share` that apps use instead of scattering files in `$HOME`
- **XDG User Directories** — named folders like `~/Documents`, `~/Downloads`, `~/Pictures` etc., configurable via `~/.config/user-dirs.dirs`
- **MIME types / default apps** — which application opens which file type (e.g. `.jpg` → Loupe, `.mp4` → Showtime)
- **Desktop entries** — `.desktop` files that describe applications (name, icon, exec command) for launchers

### In this project

**File:** `modules/home-manager/misc/xdg/default.nix`

#### Default Applications (MIME)

Three apps are registered as defaults for their respective file types:

| App | What it handles |
|---|---|
| `gnome-text-editor` | Plain text files (`.txt`, etc.) |
| `loupe` | Image files (`.jpg`, `.png`, `.webp`, etc.) |
| `showtime` | Video files (`.mp4`, `.mkv`, etc.) |

`mimeApps` uses `defaultApplicationPackages` which automatically generates the correct MIME associations from each package's declared capabilities.

#### Hidden Desktop Entries

Three internal/configuration tools are hidden from the Albert launcher and any other app list:

| Entry | Why hidden |
|---|---|
| `uuctl` | Internal UWSM session management tool, not a user-facing app |
| `qt6ct` | Qt settings GUI, not needed in normal use |
| `kvantummanager` | Kvantum theme manager GUI, not needed in normal use |

Setting `noDisplay = true` keeps them out of launchers without uninstalling them.

#### User Directories

`userDirs.enable = true` with `createDirectories = true` ensures the standard XDG folders (`~/Documents`, `~/Downloads`, `~/Pictures`, `~/Videos`, `~/Music`, `~/Desktop`, `~/Public`, `~/Templates`) are created if they don't already exist.

---

## How Everything Connects

```
Noctalia (shell: bar, notifications, lock screen, wallpaper, control centre)
    │
    ├── Hypridle ──────────────── detects inactivity → tells Noctalia to lock
    │
    ├── Kanshi ─────────────────── detects display changes → adjusts monitor layout
    │
    └── GTK + Qt + XDG ─────────── ensure all apps (GTK, Qt, file pickers)
                                    look consistent and open the right files
                                    with the right apps
```

All visual theming (GTK, Qt, Noctalia colours, cursor) flows from a single source of truth — the `catppuccin.flavor = "mocha"` and `catppuccin.accent = "lavender"` values in `common/default.nix`.
