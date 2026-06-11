# Anytype Troubleshooting

## Issue: Anytype only accessible from the command line

Anytype installs and runs fine from a terminal (`anytype`) but does not appear in — or cannot be launched from — the GNOME application launcher.

## Root cause

When a package is installed via `home.packages` in standalone home-manager, its `.desktop` file ends up at:

```
~/.nix-profile/share/applications/anytype.desktop
```

For GNOME to find this, `XDG_DATA_DIRS` must include `~/.nix-profile/share`. NixOS sets this in `/etc/environment`:

```
export XDG_DATA_DIRS="....:$HOME/.nix-profile/share:..."
```

The problem is that `/etc/environment` is processed by `pam_env` when GDM starts the session. `pam_env` does not reliably expand shell variables like `$HOME` — so the path is passed literally and GNOME never finds the `.desktop` file. Packages that ship their own `.desktop` files (Electron apps like Anytype and Discord are common examples) silently fail to appear in the launcher as a result.

This does **not** affect packages in `environment.systemPackages`, because those land in `/run/current-system/sw/share/applications/`, which is a hardcoded store path in `XDG_DATA_DIRS` — no variable expansion required.

## Fix

Move anytype (and any other affected apps) from home-manager to `environment.systemPackages` in the NixOS host config (`hosts/nixos/default.nix`):

```nix
environment.systemPackages = with pkgs; [
  anytype
  discord
];
```

And remove the corresponding home-manager import:

```nix
# home/dominic/nixos/default.nix — removed:
# "${nhModules}/programs/anytype"
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Rule of thumb

On NixOS with GNOME and standalone home-manager: install GUI apps that need a `.desktop` file via `environment.systemPackages`, not `home.packages`. CLI tools and apps without launchers are fine in home-manager.
