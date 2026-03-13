# Desktop Environment Components

This document explains the five key components that make up the Linux desktop in this config: Wayland, Hyprland, Niri, Atuin, and Albert.

---

## 1. Wayland

### What it is

Wayland is a **display server protocol** — the low-level communication standard that sits between the Linux kernel and the graphical applications you run. It replaces the older X11 (X.Org) protocol.

In the X11 world, a separate "X server" process handled all rendering and input routing, which introduced complexity and security weaknesses (any application could, for example, read keystrokes from other applications). Wayland removes the middleman: each application renders its own content and hands the finished frame directly to the **compositor**, which is the single program responsible for combining all windows onto the screen and routing input events.

Key properties of Wayland:
- **Security** — applications are isolated; one app cannot snoop on another's keyboard input or screen content
- **Performance** — fewer round trips between processes; screen tearing is eliminated by design
- **Modern GPU support** — built around direct rendering (DRM/KMS), fitting naturally with how modern graphics stacks work
- **No network transparency by default** — unlike X11, Wayland does not natively support forwarding GUIs over a network connection (though workarounds exist)

Because Wayland is only a protocol, you need a **Wayland compositor** to actually run a desktop. Hyprland and Niri are both Wayland compositors.

### In this project

**Files:** `modules/nixos/desktop/wayland-common/default.nix`, `modules/home-manager/desktop/wayland-common/default.nix`

Both the Hyprland and Niri modules share a `wayland-common` base layer. At the system level this enables:

- **GDM** as the display manager (login screen)
- **Power management** via `power-profiles-daemon` and `upower`
- **GNOME Keyring** for storing secrets (passwords, SSH keys, GPG passphrases)
- **Polkit** for privilege escalation dialogs ("enter your password to continue")

Common system packages installed for any Wayland session:

| Package | Purpose |
|---|---|
| `grim` / `grimblast` | Screenshot tools |
| `slurp` | Region selector (used with grim) |
| `pamixer` / `pavucontrol` | Audio volume control |
| `gpu-screen-recorder` | Screen recording |
| `libnotify` | Send desktop notifications |
| `nautilus` | File manager |
| `gnome-calculator` | Calculator |
| `gnome-pomodoro` | Pomodoro timer |

At the home-manager level, `wayland-common` pulls in GTK/Qt theming, XDG portal settings, the `hypridle` screen lock service, and the `kanshi` display layout manager.

`xwayland` is enabled on both compositors, which provides backwards compatibility for older X11 applications that haven't been ported to Wayland yet.

---

## 2. Hyprland

### What it is

Hyprland is a **dynamic tiling Wayland compositor**. It manages your windows — placing, resizing, and animating them — and handles all keyboard/mouse input at the desktop level.

"Dynamic tiling" means windows are automatically arranged into a grid (a **tiling layout**) that fills the whole screen without gaps, so you never manually drag and position windows. You can also make individual windows **floating** when needed.

Hyprland is written in C++ and is known for:
- Smooth animations and visual polish (though animations are disabled here for performance)
- Highly configurable via a plain-text `hyprland.conf`
- First-class multi-monitor support
- Active development and a large user community

It is the **primary compositor** used on both Linux machines (`energy` and `nabokikh-z13`).

### In this project

**System:** `modules/nixos/desktop/hyprland/default.nix`
**Home:** `modules/home-manager/desktop/hyprland/default.nix`
**Config:** `modules/home-manager/desktop/hyprland/hyprland.conf`

Hyprland is launched through **UWSM** (Universal Wayland Session Manager), which properly sets up a systemd user session before starting the compositor. This makes services like the GNOME Keyring, notification daemons, and auto-started apps behave reliably.

#### Layout

The **master layout** is used. One window is the "master" (on the left, taking 50% of the screen by default); all other windows stack vertically on the right. `Super+Return` swaps the focused window into the master position. `Super+R` cycles the orientation.

#### Window Rules

Applications are automatically sent to specific workspaces:

| Workspace | Application |
|---|---|
| 1 | Brave (browser) |
| 2 | Alacritty (terminal) |
| 3 | Telegram |
| 4 | Steam (silently, no focus steal) |
| 5 | Steam games (fullscreen) |
| Special | GNOME Pomodoro (scratchpad) |

Certain windows are forced to float (dialogs, calculator, audio mixer, Albert launcher).

#### Key Bindings (Super = Windows key)

| Binding | Action |
|---|---|
| `Super+H/J/K/L` | Move focus (vim-style) |
| `Super+Shift+H/J/K/L` | Resize window |
| `Super+Q` | Close window |
| `Super+F` | Toggle floating |
| `Super+M` | Toggle fullscreen |
| `Super+1–0` | Switch workspace |
| `Super+Shift+1–0` | Move window to workspace |
| `Super+Shift+Return` | Open Alacritty |
| `Super+Shift+B` | Open Brave |
| `Super+Shift+F` | Open Nautilus |
| `Super+A` | Open Albert (app launcher) |
| `Ctrl+Space` | Toggle Albert |
| `Super+Shift+S` | Screenshot area → Swappy |
| `Super+Shift+C` | Color picker → clipboard |
| `Ctrl+Alt+L` | Lock screen |
| `Super+C` | Toggle control center |

#### Visual Settings

- Window border: 1px, lavender (`#b7bdf8`) — matches the Catppuccin accent
- Rounded corners: 8px radius
- Blur and shadows: **disabled** (clean, minimal look and better performance)
- Animations: **disabled**
- VRR (variable refresh rate): enabled in adaptive mode (`vrr = 2`)
- Direct scanout enabled for games

---

## 3. Niri

### What it is

Niri is a **scrollable-tiling Wayland compositor**. Unlike traditional tiling compositors where windows fill a fixed grid, Niri arranges windows in an **infinitely scrollable horizontal strip of columns**. You never run out of space — you just scroll right to see more windows.

Key concepts:
- **Columns** — windows stack vertically within a column; columns scroll horizontally
- **No predefined grid** — there's no concept of "this workspace has a 2×2 layout"; you just keep adding columns
- **Named workspaces** — workspaces have names rather than numbers (though numbers still work)
- **Scroll-centric navigation** — you move left/right between columns, and up/down between windows in a column

Niri is newer than Hyprland and takes a different philosophy: it's more opinionated (less to configure, more consistent behaviour), written in Rust, and focuses on the scrollable metaphor as a first-class feature rather than an afterthought.

### In this project

**System:** `modules/nixos/desktop/niri/default.nix`
**Home:** `modules/home-manager/desktop/niri/default.nix`
**Config:** `modules/home-manager/desktop/niri/config.kdl`

Niri is configured as an **alternative compositor** — a second option alongside Hyprland. The config is written in KDL (a document language similar to JSON/TOML).

Because Niri doesn't have a built-in Xwayland server (unlike Hyprland), it uses **`xwayland-satellite`** — a standalone process that provides X11 compatibility as a separate service.

#### Layout

- Default column width: 50% of the screen
- Preset widths cycle through: 50% → 66.7% → 33.3% (toggled with `Super+R`)
- Gaps between windows: 6px
- Focus ring: 1px lavender, matching Catppuccin accent
- Rounded corners: 8px (applied globally via window rule)
- Animations: **disabled**
- VRR: on-demand for `DP-1`

#### Workspaces

Named workspaces (compared to Hyprland's numbered ones):

| Workspace | Application |
|---|---|
| `main` | Brave |
| `terminal` | Alacritty |
| `messages` | Telegram |
| `steam` | Steam |
| `games` | Steam games (fullscreen + VRR) |

#### Key Bindings

The bindings mirror Hyprland almost exactly, so muscle memory transfers between the two compositors:

| Binding | Action |
|---|---|
| `Mod+H/J/K/L` | Move focus (vim-style) |
| `Mod+Ctrl+H/J/K/L` | Move window/column |
| `Mod+Q` | Close window |
| `Mod+F` | Toggle floating |
| `Mod+M` | Maximize column |
| `Mod+Shift+M` | Fullscreen window |
| `Mod+W` | Toggle tabbed column display |
| `Mod+O` | Toggle overview (bird's-eye view) |
| `Mod+R` | Cycle preset column widths |
| `Mod+U/I` | Focus workspace down/up |
| `Mod+Space` | Switch keyboard layout (PL↔RU) |
| `Ctrl+Space` | Toggle Albert |
| `Ctrl+Alt+L` | Lock screen |

---

## 4. Atuin

### What it is

Atuin is a **shell history replacement**. It replaces the default up-arrow / `Ctrl+R` history search with a full-featured, searchable, and optionally syncable history database.

Standard shell history has several problems:
- It's stored as a flat text file, easily corrupted or overwritten
- Searching (`Ctrl+R`) is a simple substring match, one result at a time
- History is per-machine; switching computers means losing context
- There's no metadata (which directory the command ran in, exit code, how long it took)

Atuin solves all of these:
- History is stored in a **SQLite database** with timestamps, working directory, exit codes, and durations
- Search is fast and fuzzy, showing multiple results in a TUI (terminal UI)
- History can be **end-to-end encrypted and synced** across machines via Atuin's server (or a self-hosted instance)
- Supports multiple search modes: fuzzy, prefix, full-text

### In this project

**File:** `modules/home-manager/programs/atuin/default.nix`

```nix
programs.atuin = {
  enable = true;
  settings = {
    inline_height = 25;   # Show 25 results in-line (no full-screen takeover)
    invert = true;        # Most recent results at the bottom (closest to cursor)
    records = true;       # Use the new records-based sync format
    search_mode = "skim"; # Fuzzy search using skim algorithm
    secrets_filter = true; # Automatically hide commands containing secrets
    style = "compact";    # Compact UI, no borders/padding
  };
  flags = [ "--disable-up-arrow" ];  # Don't hijack the up-arrow key
};
```

The `--disable-up-arrow` flag means the up-arrow still cycles through history the normal way; Atuin is only triggered by `Ctrl+R`. This avoids surprising behaviour when pressing up in a shell.

`secrets_filter = true` is a notable safety feature — it scans command history for patterns that look like passwords, tokens, or secrets and hides them from search results, preventing accidental leakage if someone shoulder-surfs while you search history.

---

## 5. Albert

### What it is

Albert is a **keyboard-driven application launcher and quick-action tool** for Linux. Think of it as the Linux equivalent of macOS Spotlight or Alfred — press a hotkey, a search bar appears in the centre of the screen, type something, and instantly launch apps, open bookmarks, run system commands, perform calculations, and more.

Albert is extensible via plugins:
- **Applications** — fuzzy-search installed apps and launch them
- **Chromium** — search browser bookmarks (triggered with `bm`)
- **System** — quick access to lock, logout, shutdown, reboot (triggered with `sys`)
- **Calculator** — inline arithmetic
- **Web search**, **files**, **clipboard**, and many more plugins available

### In this project

**File:** `modules/home-manager/programs/albert/default.nix`

Albert is **Linux-only** — the module is wrapped in `lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin)`, so it is not installed on the macOS machine (which uses Raycast instead).

#### Configuration

```ini
[General]
showTray=false      # No system tray icon (clean taskbar)
telemetry=false     # No usage data sent

[applications]
enabled=true
global_handler_enabled=true   # Apps searchable from the main prompt

[chromium]
enabled=true
fuzzy=false
trigger=bm          # Type "bm <query>" to search Brave bookmarks

[system]
trigger=sys         # Type "sys" to get lock/logout/shutdown options
command_poweroff=systemctl poweroff -i
command_reboot=systemctl reboot -i
command_logout=$HOME/.local/bin/quit-all-applications

[widgetsboxmodel]
showCentered=true       # Always appears in the screen centre
clearOnHide=true        # Input clears when dismissed
hideOnFocusLoss=true    # Dismisses when you click elsewhere
historySearch=true      # Previous queries are remembered
itemCount=10            # Show 10 results max
alwaysOnTop=true        # Floats above all other windows
```

#### How it's launched

Albert runs as a **systemd user service** that starts automatically after the graphical session is ready:

```nix
systemd.user.services.albert = {
  After = [ "graphical-session.target" ];
  Service.Restart = "always";   # Restarts immediately if it crashes
};
```

#### Bindings (same in both Hyprland and Niri)

| Binding | Action |
|---|---|
| `Ctrl+Space` | Toggle Albert (show/hide) |
| `Super+A` | Open Albert pre-filtered to the apps plugin |

In both `hyprland.conf` and `niri/config.kdl`, Albert's window is given special floating rules — no border, no focus ring — so it appears as a clean, borderless overlay.

---

## How They Fit Together

```
Wayland (protocol)
  └── Hyprland or Niri (compositor — manages windows, input, workspaces)
        ├── Albert (launcher — invoked via Ctrl+Space, floats above everything)
        ├── Alacritty → tmux → Zsh → Starship (terminal stack)
        └── All other apps (Brave, Telegram, Nautilus, etc.)

Atuin (runs inside Zsh — replaces shell history search with Ctrl+R)
```

Hyprland and Niri are interchangeable options — both share the same keybindings, workspace assignments, and application rules, so the day-to-day experience is nearly identical. Hyprland is the default session (`defaultSession = "hyprland-uwsm"`).
