# Gaming Setup

This document covers the gaming-related tools and modules configured in this repo.

---

## Steam (`hosts/modules/steam.nix`)

**Steam** is Valve's game distribution platform for Linux. It handles game purchases, downloads, updates, and launching. The NixOS module enables it at the system level.

### What the config does

- `programs.steam.enable = true` — installs Steam and enables Pressure Vessel (the container runtime Steam uses to run games in an isolated environment)
- `remotePlay.openFirewall = true` — opens the UDP ports Steam needs for **Steam Remote Play**, which lets you stream games from this machine to other devices on the network (or over the internet via Steam's relay servers)

### Notable Steam features on Linux

- **Proton** — Steam's built-in compatibility layer (based on Wine + patches) for running Windows-only games. Enabled per-game in Steam settings. Proton GE (community fork) can be installed separately for better compatibility.
- **Steam Play** — the umbrella term for running Windows games via Proton on Linux.

---

## Lutris (`hosts/modules/lutris.nix`)

**Lutris** is an open-source game manager that goes beyond Steam — it can launch and manage games from GOG, Epic Games Store, Battle.net, itch.io, emulators, and more, all from a single interface.

It uses community-maintained install scripts to automate setup of games and their dependencies (Wine versions, DLLs, runtime settings).

### What the config does

- `lutris` — installs the Lutris application
- `wineWowPackages.stable` — installs **Wine** with both 32-bit and 64-bit support ("WoW64" = Windows on Windows 64-bit). This is what Lutris uses under the hood to run Windows executables on Linux.

### Wine

**Wine** (Wine Is Not an Emulator) is a compatibility layer that translates Windows API calls into Linux equivalents in real time. It's not emulation — it runs Windows binaries natively, just re-routing system calls. `wineWowPackages.stable` is the variant that bundles both `wine32` and `wine64` so it can run both 32-bit and 64-bit Windows applications.

---

## CoreCtrl (`hosts/modules/corectrl.nix`)

**CoreCtrl** is a GUI application for monitoring and overclocking AMD CPUs and GPUs on Linux. It exposes controls that would normally require AMD's Windows Radeon Software.

### What the config does

- `programs.corectrl.enable = true` — installs CoreCtrl and sets up the required kernel module access
- `gpuOverclock.enable = true` — enables GPU overclocking support
- `ppfeaturemask = "0xffffffff"` — sets the AMD GPU driver feature mask to unlock **all** tunable features: power limits, fan curves, core/memory clocks, voltage offsets, etc. Without this, many controls are grayed out.
- **Polkit rule** — allows any user in the `users` group to launch CoreCtrl's privileged helper without being prompted for a password. Without this, CoreCtrl asks for sudo credentials every time it starts.

### What you can do with CoreCtrl

- Set GPU performance profiles (auto, manual, power-save)
- Adjust core/memory clock speeds and voltages
- Configure custom fan curves
- Monitor GPU/CPU temperatures, clocks, and utilization in real time
