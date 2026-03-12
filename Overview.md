# Overview

This is a NixOS and nix-darwin configuration repository using Nix Flakes. It manages multiple machines (`energy` running NixOS, `PL-OLX-KCGXHGK3PY` running macOS) and users (`nabokikh`, `alexander.nabokikh`) with shared modular configurations.

## Common Commands

### Apply system configuration

```sh
# NixOS (auto-detects hostname)
make nixos-rebuild
# or explicitly:
sudo nixos-rebuild switch --flake .#energy

# macOS
make darwin-rebuild
# or explicitly:
sudo darwin-rebuild switch --flake .#PL-OLX-KCGXHGK3PY
```

### Apply home-manager configuration

```sh
make home-manager-switch
# or explicitly:
home-manager switch --flake .#nabokikh@energy
home-manager switch --flake .#alexander.nabokikh@PL-OLX-KCGXHGK3PY
```

### Validate and update

```sh
make flake-check       # Validate flake syntax
make flake-update      # Update all flake inputs (nix flake update)
make nix-gc            # Garbage collect old generations
```

> **Note:** New files must be staged with `git add` before they are visible to Nix (flakes use git's tracked files).

## Architecture

### Flake structure (`flake.nix`)

Three factory functions create configurations:
- `mkNixosConfiguration hostname username` — NixOS system config
- `mkDarwinConfiguration hostname username` — macOS (nix-darwin) system config
- `mkHomeConfiguration system username hostname` — home-manager user config

Each factory injects `specialArgs`/`extraSpecialArgs` with:
- `userConfig` — the user's record from the `users` attrset (name, email, avatar, wallpaper)
- `nixosModules` / `darwinModules` / `nhModules` — string path to the relevant modules directory (used as `"${nixosModules}/common"` in imports)
- `inputs`, `outputs`, `hostname`

#### `userConfig` fields

| Field | Usage | How to find/set |
|---|---|---|
| `name` | Linux/macOS username (used for `home.username` and `homeDirectory`) | Your system username |
| `fullName` | Git `user.name` | Your display name |
| `email` | Git `user.email` | Your email address |
| `avatar` | Path to user avatar image file (used by display managers) | A PNG/JPG file path relative to the flake root |
| `wallpaper` | Path to desktop wallpaper image | A JPG/PNG file path relative to the flake root |

### Directory layout

```
hosts/<hostname>/         # System-level config (hardware, networking, desktop choice)
home/<username>/<hostname>/  # Entry point for home-manager; imports nhModules
modules/
  nixos/                  # NixOS system modules (common, desktop/*, programs/gaming)
  darwin/                 # macOS system modules (common)
  home-manager/           # User-space modules (common, programs/*, services/*, scripts/)
files/
  avatar                  # User avatar image
  wallpaper.jpg           # Desktop wallpaper
  screenshots/            # Screenshots for README
```

### Module conventions

- Every module is a `default.nix` file; imported via string path e.g. `"${nixosModules}/desktop/niri"`.
- The `home-manager/common/default.nix` is the aggregate that imports most user programs.
- Platform conditionals use `pkgs.stdenv.hostPlatform.isDarwin` / `.isLinux`.
- Theme is Catppuccin mocha (lavender accent) applied globally via the `catppuccin` flake input and its home-manager module.

### What `home-manager/common` installs

`modules/home-manager/common/default.nix` unconditionally imports these program modules:

| Module | What it configures |
|---|---|
| `programs/aerospace` | Tiling WM for macOS (disabled on Linux) |
| `programs/alacritty` | Terminal emulator with tmux integration |
| `programs/albert` | App launcher (Linux only) |
| `programs/atuin` | Shell history with cloud sync |
| `programs/bat` | `cat` replacement with syntax highlighting |
| `programs/brave` | Browser with XDG MIME associations (Linux only) |
| `programs/btop` | Resource monitor |
| `programs/fastfetch` | System info display |
| `programs/fzf` | Fuzzy finder |
| `programs/git` | Git + `delta` diffs + GPG commit signing |
| `programs/go` | Go toolchain env |
| `programs/gpg` | GPG agent |
| `programs/k8s` | kubectl, k9s, kubectx |
| `programs/lazygit` | Terminal Git UI |
| `programs/neovim` | LazyVim-based Neovim |
| `programs/saml2aws` | AWS SAML auth |
| `programs/starship` | Shell prompt |
| `programs/telegram` | Telegram desktop |
| `programs/tmux` | Terminal multiplexer |
| `programs/zsh` | Zsh with aliases and completions |
| `scripts` | Custom scripts deployed to `~/.local/bin` |

Common packages (not via dedicated modules): `awscli2`, `dig`, `eza`, `fd`, `github-copilot-cli`, `jq`, `nh`, `nodejs`, `opencode`, `openconnect`, `pipenv`, `podman-compose`, `podman-tui`, `python3`, `ripgrep`, `terraform`. Darwin additionally gets `anki-bin`, `colima`, `hidden-bar`, `mos`, `podman`, `raycast`.

### Using home-manager on a non-NixOS Linux distro

On a standard Linux distro (Ubuntu, Arch, Fedora, etc.) you only use `homeConfigurations` — there is no `nixosConfigurations` entry needed.

1. **Install Nix** (if not already present):

   ```sh
   curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
   ```

2. **Add yourself to `flake.nix`** — add a user entry and a `homeConfigurations` entry:

   ```nix
   users = {
     newuser = {
       avatar    = ./files/avatar;
       wallpaper = ./files/wallpaper.jpg;
       email     = "you@example.com";
       fullName  = "Your Name";
       name      = "newuser";   # must match your Linux username
     };
   };

   homeConfigurations = {
     "newuser@myhostname" = mkHomeConfiguration "x86_64-linux" "newuser" "myhostname";
   };
   ```

3. **Create the home entry point**:

   ```sh
   mkdir -p home/newuser/myhostname
   ```

   `home/newuser/myhostname/default.nix`:

   ```nix
   { nhModules, ... }:
   {
     imports = [
       "${nhModules}/common"
       # optionally add desktop modules, e.g.:
       # "${nhModules}/desktop/wayland-common"
     ];
   }
   ```

4. **Stage new files** (required by flakes):

   ```sh
   git add .
   ```

5. **Bootstrap and apply** (first time only needs `nix-shell`):

   ```sh
   nix-shell -p home-manager --run \
     "home-manager switch --flake .#newuser@myhostname"
   ```

   After bootstrapping, `home-manager` is on your `$PATH` and you can run it directly:

   ```sh
   home-manager switch --flake .#newuser@myhostname
   ```

> **Note:** Desktop modules (`desktop/hyprland`, `desktop/niri`, `desktop/wayland-common`) depend on system-level packages (GDM, Wayland compositors) that must be installed outside of Nix on a foreign distro. The `common` module works standalone.

### Migrating from a traditional `configuration.nix` setup to this flake

A default NixOS install puts everything in `/etc/nixos/configuration.nix` and `/etc/nixos/hardware-configuration.nix` and is not managed by a flake. This section covers how to move to this repo's structure.

#### 1. Enable flakes (if not already)

Add this to your existing `configuration.nix` before doing anything else, then rebuild once:

```nix
nix.settings.experimental-features = "nix-command flakes";
```

#### 2. Clone this repo and take stock of your current config

```sh
git clone <repo-url> ~/nix-config
cd ~/nix-config
```

Your current `/etc/nixos/configuration.nix` likely contains things like: timezone, locale, networking, user definitions, system packages, desktop environment. Compare it against what `modules/nixos/common/default.nix` already handles:

| Already in `common` | You may still need to port |
|---|---|
| Bootloader (systemd-boot + Plymouth) | Your specific `boot.loader` settings if not systemd-boot |
| NetworkManager | Static IPs, VPN configs, firewall rules |
| PipeWire (ALSA + PulseAudio + JACK) | Extra audio devices or JACK settings |
| Bluetooth | — |
| Fonts (JetBrains Mono, Meslo, Roboto Nerd Fonts) | Any other fonts you installed |
| Zsh enabled system-wide | Other shells |
| Podman + containers | Docker (not included) |
| Timezone (`Europe/Warsaw`) | **Your own timezone** |
| Locale (`en_US.UTF-8` / `en_IE`) | **Your own locale settings** |
| User with `wheel`/`networkmanager`/`video` groups | Any extra groups (e.g. `docker`, `dialout`) |

> The `common` module sets timezone to `Europe/Warsaw` and locale to `en_IE` — you will need to override these for your machine.

#### 3. Copy your hardware configuration

```sh
cp /etc/nixos/hardware-configuration.nix hosts/<yourhostname>/hardware-configuration.nix
```

Do **not** regenerate it — copy the one NixOS created for your machine, as it contains correct UUIDs and filesystem settings.

#### 4. Create your host entry

`hosts/<yourhostname>/default.nix`:

```nix
{ inputs, hostname, nixosModules, ... }:
{
  imports = [
    # Add nixos-hardware modules matching your hardware, e.g.:
    # inputs.hardware.nixosModules.common-cpu-intel
    # inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/niri"   # or /desktop/hyprland
  ];

  networking.hostName = hostname;

  # Override timezone and locale from common:
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Any settings from your old configuration.nix not covered by common:
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # users.users.yourname.extraGroups = [ "docker" ];

  system.stateVersion = "24.11"; # keep your original stateVersion
}
```

> **`system.stateVersion`**: copy the exact value from your old `configuration.nix`. Never change this to a newer version — it controls stateful data migration, not which packages are installed.

#### 5. Add yourself to `flake.nix`

```nix
users = {
  yourname = {
    avatar    = ./files/avatar;      # add a photo, or reuse the existing one
    wallpaper = ./files/wallpaper.jpg;
    email     = "you@example.com";
    fullName  = "Your Name";
    name      = "yourname";          # must match your Linux username exactly
  };
};

nixosConfigurations = {
  yourhostname = mkNixosConfiguration "yourhostname" "yourname";
};

homeConfigurations = {
  "yourname@yourhostname" = mkHomeConfiguration "x86_64-linux" "yourname" "yourhostname";
};
```

#### 6. Create your home-manager entry point

```sh
mkdir -p home/yourname/yourhostname
```

`home/yourname/yourhostname/default.nix`:

```nix
{ nhModules, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/wayland-common"
    # "${nhModules}/desktop/niri"      # if using Niri
    # "${nhModules}/desktop/hyprland"  # if using Hyprland
  ];
}
```

#### 7. Stage everything and switch

```sh
git add .
sudo nixos-rebuild switch --flake .#yourhostname
```

If this succeeds, your system is now managed by the flake. Afterwards bootstrap home-manager:

```sh
nix-shell -p home-manager --run \
  "home-manager switch --flake .#yourname@yourhostname"
```

#### 8. Clean up

Once the flake rebuild works, the old `/etc/nixos/configuration.nix` is no longer used. You can leave it in place (it won't interfere) or archive it:

```sh
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak
```

### What was removed vs. master

The `upstream-sync` branch represents a large refactoring. The items below were in `master` but are not present in this branch. "Replaced" means equivalent functionality exists under a different module; "removed" means it is gone entirely.

#### System-level modules (`hosts/modules/` → removed)

| Module | What it did | Status |
|---|---|---|
| `steam.nix` | Basic Steam enable + remote play firewall | **Replaced** by `modules/nixos/programs/gaming` (adds GameMode, CPU governor, low-latency audio) |
| `corectrl.nix` | AMD GPU overclocking/monitoring via CoreCtrl + polkit rule | **Removed** (GPU tuning now handled by the gaming module) |
| `gnome.nix` | Enabled GNOME, excluded unwanted default apps | **Removed** (desktop switched to Niri/Hyprland) |
| `laptop.nix` | TLP power management (CPU governor, battery charge thresholds) | **Removed** (the `nabokikh-z13` laptop host is gone; desktop `energy` doesn't need TLP) |
| `lutris.nix` | Lutris game launcher + Wine | **Removed** |
| `ollama.nix` | Ollama local AI model runner (with optional AMD ROCm acceleration) | **Removed** |

#### Home-manager modules (`home/modules/` → removed)

| Module | What it did | Status |
|---|---|---|
| `spicetify.nix` | Spotify UI customisation (Catppuccin macchiato theme, keyboard shortcuts, shuffle) | **Removed** — see `AddingApps.md` for how to restore it |
| `zoom.nix` | Zoom pinned to v6.0.2 (last version with working Wayland screen sharing) | **Removed** |
| `easyeffects.nix` | PipeWire mic effects service (compressor, noise gate, EQ) with preset | **Removed** |
| `cliphist.nix` | Clipboard history manager (`cliphist`) bound to Hyprland session | **Removed** |
| `waybar.nix` | Waybar status bar with config sourced from `files/configs/waybar/` | **Replaced** by Noctalia Shell bar (`modules/home-manager/programs/noctalia`) |
| `wofi.nix` | Wofi application launcher | **Replaced** by Albert (`modules/home-manager/programs/albert`) |
| `ulauncher.nix` | Ulauncher launcher with extensions, shortcuts, and Catppuccin theme | **Replaced** by Albert |
| `swaync.nix` | Sway Notification Center with config sourced from `files/configs/swaync/` | **Removed** |
| `bottom.nix` | `bottom` (`btm`) system monitor | **Replaced** by btop (`modules/home-manager/programs/btop`) |
| `krew.nix` | kubectl plugin manager (`krew`) with plugins: ctx, get-all, ns, rbac-lookup, stern | **Removed** (basic k8s tools remain via `programs/k8s`) |
| `normcap.nix` | NormCap GUI OCR tool | **Removed** — replaced by `tesseract` package + custom `ocr` script in `modules/home-manager/scripts/bin/` |
| `flameshot.nix` | Flameshot screenshot tool (Wayland mode, configured save path) | **Removed** — replaced by `swappy` (`modules/home-manager/programs/swappy`) |
| `gnome.nix` | Full GNOME dconf settings, wallpaper, pop-shell, GTK, XDG, flameshot | **Removed** (GNOME desktop dropped) |
| `pop-shell.nix` | GNOME Pop!_OS tiling extension config | **Removed** (GNOME dropped) |

#### Removed hosts

| Host | What it was |
|---|---|
| `nabokikh-z13` | Asus ROG Zephyrus G13 laptop running NixOS |
| `nabokikh-mac` | Old macOS machine (renamed to `PL-OLX-KCGXHGK3PY`) |

#### Removed overlays

`overlays/default.nix` — custom nixpkgs overlays were removed. Any package overrides previously defined there now need to be expressed as module-level `pkgs.override` calls or moved back into an overlays file.

### Adding a new machine/user

1. Add user to `users` attrset in `flake.nix`.
2. Add `nixosConfigurations`/`darwinConfigurations` and `homeConfigurations` entries using the mk* helpers.
3. Create `hosts/<hostname>/default.nix` importing the desired system modules.
4. Create `home/<username>/<hostname>/default.nix` importing `"${nhModules}/common"` and any extras.
5. For NixOS, generate hardware config: `sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix`.
6. `git add` all new files before rebuilding.
