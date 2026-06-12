# MacBook Setup

This guide bootstraps `nix-darwin` and applies the `dominic-macbook` system and Home Manager profiles from this repo. Assumes Nix is already installed.

## Assumptions

- Machine: Apple Silicon MacBook
- macOS user: `dominic`
- Repo location: `~/Desktop/nix-config`
- Host/profile names in this repo:
  - `darwinConfigurations.dominic-macbook`
  - `homeConfigurations."dominic@dominic-macbook"`

If your local macOS username is not `dominic`, change the user mapping in [flake.nix](/home/dominic/Desktop/nix-config/flake.nix) before applying.

## 1. Clone This Repo

```sh
mkdir -p ~/Desktop
git clone <your-repo-url> ~/Desktop/nix-config
cd ~/Desktop/nix-config
```

## 2. Bootstrap & Apply System Profile

Bootstrap `nix-darwin` and apply the system config in one step:

```sh
nix run nix-darwin -- switch --flake ~/Desktop/nix-config#dominic-macbook
```

After this, `darwin-rebuild` is available on your `PATH`. For subsequent rebuilds:

```sh
darwin-rebuild switch --flake ~/Desktop/nix-config#dominic-macbook
```

## 3. Apply the Home Manager Profile

```sh
nix run home-manager -- switch --flake ~/Desktop/nix-config#dominic@dominic-macbook
```

After the first run, `home-manager` is on your `PATH`:

```sh
home-manager switch --flake ~/Desktop/nix-config#dominic@dominic-macbook
```

## 4. Verify

```sh
which darwin-rebuild
which home-manager
which nvim
which zsh
```

## 5. Optional: Secrets

Claude Code requires an Anthropic API key at runtime. Store it outside the repo:

```sh
mkdir -p ~/.config/anthropic
chmod 700 ~/.config/anthropic
printf '%s\n' '<your-anthropic-api-key>' > ~/.config/anthropic/api-key
chmod 600 ~/.config/anthropic/api-key
```

## Common Commands

```sh
darwin-rebuild switch --flake ~/Desktop/nix-config#dominic-macbook
home-manager switch --flake ~/Desktop/nix-config#dominic@dominic-macbook
nix flake update
```
