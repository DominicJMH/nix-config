# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# NixOS rebuild
sudo nixos-rebuild switch --flake .#nixos

# macOS (nix-darwin) rebuild
darwin-rebuild switch --flake .#dominic-macbook

# Home-Manager (standalone, after system rebuild)
home-manager switch --flake .#dominic@nixos
home-manager switch --flake .#dominic@dominic-macbook

# Update all flake inputs
nix flake update

# Check configuration syntax
nix flake check

# Bootstrap macOS from scratch
make bootstrap-mac
```

## Architecture

This is a Nix Flakes-based configuration managing NixOS, nix-darwin, and Home-Manager for Dominic's machines:
- **nixos**: NixOS workstation
- **dominic-macbook**: Apple Silicon macOS machine

### Key Pattern: Configuration Flow

```
flake.nix (defines users, creates configurations via helper functions)
    │
    ├── hosts/{hostname}/configuration.nix (system-level)
    │       └── imports from hosts/modules/ (common.nix, hyprland.nix, laptop.nix, etc.)
    │
    └── home/{username}/{hostname}.nix (user-level)
            └── imports from home/modules/ (common.nix loads ~15 core modules)
```

### flake.nix Structure

Three helper functions create all configurations:
- `mkNixosConfiguration hostname username` - NixOS systems
- `mkDarwinConfiguration hostname username` - macOS systems
- `mkHomeConfiguration system username hostname` - Home-Manager configs

User data is defined once in `users` attrset and passed as `userConfig` via `specialArgs`/`extraSpecialArgs`.

### Static Files

`files/` contains configs symlinked via `xdg.configFile`:
- `files/configs/nvim/` - Full Neovim Lua config
- `files/configs/hypr/` - Hyprland config
- `files/configs/waybar/` - Waybar config and styles
- `files/scripts/` - Shell scripts installed to `~/.local/bin`

### Theme System

Catppuccin (macchiato flavor, lavender accent) is integrated globally via `catppuccin.homeManagerModules.catppuccin`. Individual modules enable it with `catppuccin.{app}.enable = true`.

### Overlays

Single overlay in `overlays/default.nix` provides `pkgs.stable` for accessing nixos-24.11 packages when needed.

## Adding New Components

**New home module**: Create `home/modules/{name}.nix`, import in `home/modules/common.nix` or user-specific config.

**New system module**: Create `hosts/modules/{name}.nix`, import in host's `configuration.nix`.

**New machine**: Add user to `flake.nix` users (if new), add `mk*Configuration` call, create `hosts/{hostname}/` directory with `configuration.nix` (and `hardware-configuration.nix` for NixOS), create `home/{username}/{hostname}.nix`.

## Commit Convention

Uses conventional commits: `feat(scope):`, `fix(scope):`, `chore(scope):`
