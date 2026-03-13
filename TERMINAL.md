# Terminal Appearance

This document explains the stack of tools that give the terminal its look and feel.

---

## The Stack

### 1. Alacritty — Terminal Emulator
**File:** `modules/home-manager/programs/alacritty/default.nix`

Alacritty is the actual window you type into. It handles:
- **Font:** `MesloLGS Nerd Font` — a patched font that renders icons and glyphs (arrows, git symbols, etc.) in the prompt
- **Window size:** 170 columns × 45 lines with padding
- **Scroll history:** 10,000 lines
- **Shell:** Launches Zsh, which immediately attaches to (or creates) a tmux session

Catppuccin theming is applied directly to Alacritty via `catppuccin.alacritty.enable = true`, which sets the background, text, and 16-color palette.

---

### 2. tmux — Terminal Multiplexer
**File:** `modules/home-manager/programs/tmux/default.nix`

tmux runs inside Alacritty and provides:
- **Status bar** at the bottom showing hostname, date/time, and window names
- **Window/pane splitting** — the ability to have multiple terminals in one window
- **Prefix key:** `Ctrl+Q` (instead of the default `Ctrl+B`)
- **Vi-style** copy mode and pane navigation

Catppuccin theming (`catppuccin.tmux.enable = true`) styles the status bar with mocha colors: peach for the active window, blue for inactive, transparent background.

---

### 3. Zsh — Shell
**File:** `modules/home-manager/programs/zsh/default.nix`

Zsh is the shell that runs inside tmux. It provides:
- Tab completion
- All the aliases (`ll`, `la`, `lt` using `eza` with icons, `v` for Neovim, `lg` for lazygit, etc.)
- Key bindings (`Ctrl+H` to delete word, `Ctrl+V` to edit command in `$EDITOR`)

---

### 4. Starship — Prompt
**File:** `modules/home-manager/programs/starship/default.nix`

Starship renders the colourful prompt line inside Zsh. It shows:
- **Current directory** in bold lavender
- **Kubernetes context/namespace** on the right side (in pink)
- **Language/tool icons** for Go, Rust, Python, Lua, etc. when inside relevant projects
- **Git status** (built in to Starship by default)

Catppuccin theming (`catppuccin.starship.enable = true`) ensures all prompt colours stay consistent with the rest of the theme.

---

### 5. Fastfetch — System Info Display
**File:** `modules/home-manager/programs/fastfetch/default.nix`

Run with the alias `ff`. Prints a styled system info panel (OS, kernel, CPU, GPU, memory, IP, etc.) with coloured labels and a palette swatch. No logo — just clean info in a box.

---

## What Catppuccin Does

Catppuccin is a **colour scheme / theming framework**. It defines a palette of soft, pastel colours and provides ready-made themes for dozens of applications.

In this config, the global settings are:

```nix
catppuccin = {
  flavor = "mocha";   # darkest variant (others: latte, frappe, macchiato)
  accent = "lavender";
};
```

The `mocha` flavour gives a dark background with warm, muted pastels. `lavender` is used as the primary accent colour (e.g. the directory in the Starship prompt).

Catppuccin is enabled **per application**:

| Application | What it themes |
|---|---|
| `alacritty` | Terminal background, text colour, 16-colour ANSI palette |
| `tmux` | Status bar colours, window name colours, separator style |
| `starship` | Prompt colour variables |

Because every tool uses the same palette, colours are visually consistent across the terminal, prompt, status bar, and any TUI apps that respect the 16-colour palette (like `btop`, `lazygit`, `nvim`).

---

## Summary

```
Alacritty (window + font + colours)
  └── tmux (status bar + pane management)
        └── Zsh (shell + aliases)
              └── Starship (prompt)
```

Everything is coloured by **Catppuccin Mocha** with a **lavender** accent.
