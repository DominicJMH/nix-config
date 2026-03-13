# Setup Instructions

## Applying the Configuration

### NixOS System Configuration

Build and switch to the new configuration:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

Build and switch, making it the default boot entry:

```bash
sudo nixos-rebuild boot --flake .#nixos
```

Build only (without switching):

```bash
sudo nixos-rebuild build --flake .#nixos
```

Test the configuration (switch but don't add boot entry):

```bash
sudo nixos-rebuild test --flake .#nixos
```

### Home Manager Configuration

First time (bootstrap):

```bash
nix-shell -p home-manager
home-manager switch --flake .#dominic@nixos
```

After bootstrap:

```bash
home-manager switch --flake .#dominic@nixos
```

## Testing Before Applying

### Validate flake syntax

```bash
nix flake check
```

### Dry-build NixOS (no changes applied)

```bash
nixos-rebuild dry-build --flake .#nixos
```

### Dry-run home-manager

```bash
home-manager build --flake .#dominic@nixos --dry-run
```

## Updating

Update all flake inputs:

```bash
nix flake update
```
