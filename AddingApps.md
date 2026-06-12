# Adding Creative & Gaming Applications

This document covers how to add Spicetify, Blender, Godot, Aseprite, DaVinci Resolve, and Claude Code to this flake configuration.

---

## Spicetify

Spicetify customises Spotify's UI. It was previously in this repo and was removed during the major refactoring — the config below restores it exactly as it was, with the Catppuccin theme.

### 1. Add the flake input (`flake.nix`)

```nix
inputs = {
  # ... existing inputs ...

  spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Also expose it in the `mkHomeConfiguration` `extraSpecialArgs` so modules can access `inputs`:

The `inputs` key is already passed via `extraSpecialArgs` in `mkHomeConfiguration`, so no further change is needed there.

### 2. Create the module (`modules/home-manager/programs/spicetify/default.nix`)

```nix
{
  inputs,
  pkgs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha"; # matches the repo's global Catppuccin flavor

    enabledExtensions = with spicePkgs.extensions; [
      keyboardShortcut
      shuffle
    ];
  };
}
```

> The original module used `colorScheme = "macchiato"`. Changed here to `"mocha"` to match the global theme set in `modules/home-manager/common/default.nix`. Revert if preferred.

### 3. Import it

Add to `modules/home-manager/common/default.nix` imports list:

```nix
imports = [
  # ... existing imports ...
  ../programs/spicetify
];
```

Or import it only in a specific host's home entry (`home/<username>/<hostname>/default.nix`) if you don't want it on every machine.

### 4. Apply

```sh
git add .
home-manager switch --flake .#yourname@yourhostname
```

---

## Blender

Blender is in nixpkgs and requires no flake input. It benefits from OpenCL/CUDA/ROCm GPU acceleration depending on your hardware.

### Simple install (CPU rendering only)

Add to `modules/home-manager/common/default.nix` (or a host-specific module):

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  blender
];
```

### With GPU acceleration (NixOS system module)

GPU rendering support is configured at the system level. Add to your host's `default.nix` or create `modules/nixos/programs/blender/default.nix`:

**AMD (ROCm):**

```nix
{ pkgs, ... }:
{
  hardware.amdgpu.opencl.enable = true; # NixOS 24.11+

  home.packages = [ pkgs.blender ];
}
```

**NVIDIA (CUDA):**

```nix
{ pkgs, ... }:
{
  hardware.nvidia.package = pkgs.linuxPackages.nvidiaPackages.stable;

  home.packages = [
    (pkgs.blender.override { cudaSupport = true; })
  ];
}
```

> If your NixOS machine uses an AMD GPU, ROCm is the relevant path.

---

## Godot

Godot 4 is packaged in nixpkgs as `godot_4`. Godot 3 is available as `godot3`.

### Module (`modules/home-manager/programs/godot/default.nix`)

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    godot_4

    # Optional export templates for publishing builds:
    # godot_4-export-templates
  ];
}
```

### Import it

In `modules/home-manager/common/default.nix` or a host-specific home file:

```nix
imports = [
  # ... existing imports ...
  ../programs/godot
];
```

---

## Aseprite

Aseprite's source is open but the compiled binary is paid. NixOS can **compile it from source** for free, or you can use the free Libresprite fork.

### Option A — compile from source (free, takes a few minutes on first build)

```nix
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.aseprite.override { unfree = false; })
    # On some nixpkgs versions the attribute is simply pkgs.aseprite-unfree
    # for the binary, or pkgs.aseprite for the source build.
  ];
}
```

Check the available attribute on your nixpkgs revision:

```sh
nix search nixpkgs aseprite
```

Typically:
- `pkgs.aseprite` — compiled from source (free, requires `allowUnfree = false` or the default)
- `pkgs.aseprite-unfree` — prebuilt binary (requires `nixpkgs.config.allowUnfree = true`, already set in this flake)

### Option B — Libresprite (fully free fork)

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.libresprite ];
}
```

### Module (`modules/home-manager/programs/aseprite/default.nix`)

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.aseprite ]; # source build
}
```

Import in `common` or host-specific home file as with the other modules.

---

## DaVinci Resolve

DaVinci Resolve is unfree, closed-source, and requires special handling on NixOS because it ships its own CUDA/OpenCL libraries that can conflict with system ones.

### System-level config (NixOS only)

DaVinci Resolve works best when configured at the system level. Add to your host's `default.nix` or create `modules/nixos/programs/davinci-resolve/default.nix`:

```nix
{ pkgs, ... }:
{
  # DaVinci Resolve needs OpenCL and GPU access
  hardware.amdgpu.opencl.enable = true; # for AMD; remove if using NVIDIA

  environment.systemPackages = [
    pkgs.davinci-resolve
    # For the Studio (paid) version:
    # pkgs.davinci-resolve-studio
  ];
}
```

Import it in your NixOS host config, for example `hosts/nixos/default.nix`:

```nix
imports = [
  # ... existing imports ...
  "${nixosModules}/programs/davinci-resolve"
];
```

### Known issues on NixOS

- **Crashes on launch**: DaVinci Resolve often requires `davinci-resolve` to be run via its own wrapper. The nixpkgs package handles this but may need `OCIO` or `opencl-icd-loader` adjustments.
- **AMD GPU**: If your machine uses AMD, the free version of DaVinci Resolve generally works via ROCm/OpenCL.
- **Wayland**: DaVinci Resolve runs under XWayland — it does not natively support Wayland. This is handled automatically by both Niri and Hyprland.
- **Studio version**: `pkgs.davinci-resolve-studio` requires a dongle or licence activation and is otherwise identical in setup.

### Alternative: home-manager only

If you prefer not to add it at the system level:

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.davinci-resolve ];
}
```

This works but you lose the ability to set system-wide OpenCL config from the same module.

---

## Claude Code

Claude Code is in nixpkgs as two variants: `claude-code` (built from source) and `claude-code-bin` (prebuilt binary). This repo already has `opencode` installed via `modules/home-manager/common/default.nix` — Claude Code fits naturally alongside it.

### Option A — add to `common` packages (all machines)

The simplest approach is to add it to the existing `home.packages` list in `modules/home-manager/common/default.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages ...
  claude-code-bin  # prebuilt binary; faster to install than claude-code
];
```

Use `claude-code-bin` over `claude-code` to avoid the long compile time on first install — they are functionally identical.

### Option B — dedicated module (`modules/home-manager/programs/claude-code/default.nix`)

If you want to keep it isolated (e.g. only on certain machines):

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.claude-code-bin ];
}
```

Import it only in the relevant host's home entry (`home/<username>/<hostname>/default.nix`):

```nix
{ nhModules, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/claude-code"
  ];
}
```

### API key

Claude Code requires an `ANTHROPIC_API_KEY` environment variable. Set it in your shell config rather than in Nix to avoid storing secrets in the store. Add to `modules/home-manager/programs/zsh/default.nix` or your shell's environment file:

```nix
home.sessionVariables = {
  ANTHROPIC_API_KEY = "$(cat ~/.config/anthropic/api-key)";
};
```

Then put your key in `~/.config/anthropic/api-key` (mode `600`, outside the Nix store).

### Apply

```sh
git add .
home-manager switch --flake .#yourname@yourhostname
```

---

## Summary

| App | nixpkgs attribute | Flake input needed | Level |
|---|---|---|---|
| Spicetify | via `spicetify-nix` module | Yes — `github:Gerg-L/spicetify-nix` | home-manager |
| Blender | `pkgs.blender` | No | home-manager (+ system for GPU) |
| Godot 4 | `pkgs.godot_4` | No | home-manager |
| Aseprite | `pkgs.aseprite` | No | home-manager |
| DaVinci Resolve | `pkgs.davinci-resolve` | No | system (recommended) or home-manager |
| Claude Code | `pkgs.claude-code-bin` | No | home-manager |
