# Rollback Guide

## How NixOS and Home-Manager Generations Relate

**They are completely independent.** NixOS and home-manager maintain separate generation
counters in separate Nix profiles. A NixOS generation has no knowledge of which home-manager
generation was active when it was built, and vice versa.

```
NixOS profile:        /nix/var/nix/profiles/system
                      system-1-link  system-2-link  system-3-link ...

Home-manager profile: /nix/var/nix/profiles/per-user/dominic/home-manager
                      home-manager-1-link  home-manager-2-link  ...  home-manager-6-link
```

These two counters advance independently whenever you run their respective `switch` commands.

### Answering the common questions

**"If I run `home-manager switch` 4 times within a single NixOS generation, do those 4
HM generations carry over when I build a new NixOS generation?"**

No. Switching NixOS generations has no effect on the home-manager profile. Your HM
generations 1–4 were created while on NixOS gen N and will still exist after you switch
to NixOS gen N+1. They are on separate tracks.

**"If I run `home-manager switch` after switching to a new NixOS generation, does that
change persist back to the old NixOS generation?"**

No. Activating a new NixOS generation does not activate any home-manager generation.
Whatever HM generation is currently active remains active regardless of NixOS switches.
You manage them independently.

**In practice this means:**

- You can be on NixOS gen 3 and HM gen 9 simultaneously.
- Rolling back NixOS to gen 2 does not roll back HM.
- Rolling back HM to gen 5 does not affect NixOS.
- Neither rollback affects the other.

---

## Rolling Back NixOS

### From the bootloader (system won't boot)

At the GRUB or systemd-boot menu, select a previous generation. NixOS lists all
generations there.

### From a running system

```bash
# List all system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Roll back one generation
sudo nixos-rebuild switch --rollback

# Switch to a specific generation
sudo nix-env --switch-generation <N> --profile /nix/var/nix/profiles/system
```

After switching to an older generation you must reboot for it to take effect as the
running system. `nixos-rebuild switch --rollback` attempts an in-place switch which
may fail for critical component changes (like dbus implementation changes).

---

## Rolling Back Home-Manager

### List and switch generations

```bash
# List all home-manager generations with their dates
home-manager generations

# Roll back one generation
home-manager rollback

# Activate a specific generation directly
# (path comes from `home-manager generations` output)
/nix/store/<hash>-home-manager-generation/activate
```

Home-manager rollbacks take effect immediately without a reboot — the activation
script re-symlinks your dotfiles and reloads user services.

---

## Rolling Back via Git (before committing)

If you haven't committed the change yet, reverting the files and rebuilding is the
most precise option because you choose exactly which files to revert.

```bash
# Revert everything since the last commit
git checkout -- .

# Revert a specific file only
git checkout -- modules/home-manager/desktop/hyprland/hyprland.conf

# Or stash changes temporarily
git stash

# Then rebuild whichever layer you changed
sudo nixos-rebuild switch --flake .#nixos
home-manager switch --flake .#dominic@nixos
```

---

## Quick Reference

| Scenario | Command |
|----------|---------|
| NixOS won't boot | Select previous generation at bootloader |
| Roll back NixOS one step | `sudo nixos-rebuild switch --rollback` |
| Roll back NixOS to specific gen | `sudo nix-env --switch-generation <N> --profile /nix/var/nix/profiles/system` |
| Roll back HM one step | `home-manager rollback` |
| Roll back HM to specific gen | Run the activation script from `home-manager generations` |
| Revert uncommitted config changes | `git checkout -- <file>` then rebuild |
