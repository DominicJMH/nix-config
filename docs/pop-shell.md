# Pop Shell

Pop Shell is a GNOME extension by System76 that adds keyboard-driven auto-tiling to GNOME. Windows are automatically placed into a non-overlapping grid, and you navigate, resize, swap, and stack them entirely from the keyboard.

## Enabling It in This Config

Pop Shell is configured in the `master` branch but not yet active on this system. To enable it you need changes in three places:

### 1. Install the extension (`hosts/nixos/default.nix`)

```nix
environment.systemPackages = with pkgs; [
  gnome-tweaks
  gnomeExtensions.pop-shell
];
```

### 2. Configure via dconf (home module)

```nix
dconf.settings = {
  "org/gnome/shell" = {
    "enabled-extensions" = [ "pop-shell@system76.com" ];
  };

  "org/gnome/shell/extensions/pop-shell" = {
    "tile-by-default" = true;   # auto-tile every new window
    "active-hint" = false;      # no colored border on focused window
    "gap-inner" = lib.hm.gvariant.mkUint32 1;
    "gap-outer" = lib.hm.gvariant.mkUint32 1;
  };

  "org/gnome/mutter" = {
    "edge-tiling" = false;  # disable GNOME's built-in snap, conflicts with pop-shell
  };
};
```

### 3. Float rules (`~/.config/pop-shell/config.json`)

```json
{
  "float": [
    { "class": "ulauncher" },
    { "class": "org.gnome.Calculator" }
  ],
  "skiptaskbarhidden": [],
  "log_on_focus": false
}
```

This is managed via `xdg.configFile."pop-shell/config.json".text` in a home module. See `home/modules/pop-shell.nix` on the `master` branch for the full example.

---

## Concepts

| Term | Meaning |
|------|---------|
| **Auto-tiling** | Pop Shell places every new window into the grid automatically. Toggle with `Super + Y`. |
| **Adjustment mode** | A temporary mode for moving and resizing the focused window via keyboard. Enter with `Super + Enter`, confirm with `Enter`, cancel with `Esc`. |
| **Fork** | The split point between two tiled windows. Each fork has an orientation (horizontal or vertical). |
| **Stack** | Multiple windows occupying the same tile slot, switchable like tabs. |
| **Float** | A window removed from the tiling grid — behaves like a normal GNOME window. |

---

## Keybindings

> Direction keys are interchangeable: arrow keys or `H/J/K/L` (vim-style) both work everywhere.

### Focus

| Keys | Action |
|------|--------|
| `Super + Arrow` / `Super + H/J/K/L` | Move focus to the window in that direction |
| `Super + Tab` | Switch between applications |
| `Super + \`` | Cycle windows of the current application |

### Adjustment Mode

Enter with **`Super + Enter`**, confirm with **`Enter`**, cancel with **`Esc`**.

| Keys (while in adjustment mode) | Action |
|---------------------------------|--------|
| `Arrow` / `H/J/K/L` | Move window to adjacent tile |
| `Shift + Arrow` / `Shift + H/J/K/L` | Resize window |
| `Ctrl + Arrow` / `Ctrl + H/J/K/L` | Swap window with the one in that direction |

### Tiling

| Keys | Action |
|------|--------|
| `Super + Y` | Toggle auto-tiling on/off globally |
| `Super + O` | Flip the fork orientation (horizontal ↔ vertical) for the focused window's split |

### Stacking

| Keys | Action |
|------|--------|
| `Super + S` | Toggle stacking — group the focused window with the adjacent one into a stack |
| `Super + Arrow` / `Super + H/K` | Navigate between windows inside a stack |

To remove a window from a stack: enter adjustment mode (`Super + Enter`) and move the window out of the stack tile with an arrow key.

### Floating

| Keys | Action |
|------|--------|
| `Super + G` | Float / un-float the focused window |

Floating windows are excluded from the tiling grid and can be placed freely. Apps can be permanently floated via the `config.json` float rules (see above).

### Workspaces

| Keys | Action |
|------|--------|
| `Super + Ctrl + ↑/↓` | Switch to the workspace above/below |
| `Super + Home` / `Super + End` | Jump to the first/last workspace |
| `Super + Shift + ↑/↓` | Move focused window to the workspace above/below |
| `Super + Shift + ←/→` | Move focused window to the display on the left/right |

> In the `master` branch config, `Super + 1–9` and `Super + Shift + 1–9` are remapped to switch/move to numbered workspaces directly via `org/gnome/desktop/wm/keybindings`.

### Window Actions

| Keys | Action |
|------|--------|
| `Super + Q` | Close window |
| `Super + M` | Maximize / restore |
| `Super + Ctrl + ←` / `Super + Ctrl + →` | Snap window to left / right half of the screen |
| `Super + Enter` | Enter adjustment mode (see above) |

### Launcher

| Keys | Action |
|------|--------|
| `Super + /` | Open the Pop Shell application launcher |

---

## Tips

- **`tile-by-default = true`** means every window is tiled on open — you never need to manually enable tiling per-window. Float exceptions in `config.json` handle apps like launchers or calculators that shouldn't tile.
- **Gaps** (`gap-inner`, `gap-outer`) are set in pixels. Values of `1`–`4` give a minimal look. Set both to `0` for edge-to-edge tiling.
- **Active hint** (`active-hint = true`) draws a colored border around the focused window. Useful for orientation at a glance; the color is configurable in GNOME Tweaks.
- Pop Shell adds a small icon to the top bar where you can toggle tiling, adjust gaps visually, and reach the shortcuts reference without memorising everything upfront.
- Run `pop-shell-shortcuts` in a terminal to open the full interactive shortcuts viewer.

---

## Sources

- [Pop Shell GitHub](https://github.com/pop-os/shell)
- [Pop!_OS Keyboard Shortcuts — System76 Support](https://support.system76.com/articles/pop-keyboard-shortcuts/)
- [Tile, Stack & Resize Windows — Pop!_OS Docs](https://pop-os.github.io/docs/navigate-pop/tiling-stacking-windows.html)
