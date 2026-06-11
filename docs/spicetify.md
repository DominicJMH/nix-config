# Spicetify

Spicetify is managed declaratively via the [`spicetify-nix`](https://github.com/Gerg-L/spicetify-nix) flake input. The config lives at:

```
modules/home-manager/programs/spicetify/default.nix
```

It is imported in `home/dominic/nixos/default.nix`.

## How It Works

`spicetify-nix` wraps the Spotify package and patches it automatically on each `home-manager switch`. You never run `spicetify` CLI commands manually — everything is declared in Nix. The patched Spotify binary replaces the normal one in your `$PATH`.

The patching happens entirely at **build time** inside a Nix derivation. The result is a sealed, read-only store path. There is no mutable spicetify config at runtime — `spicetify-cli` is intentionally not exposed to the user.

## Current Config

```nix
programs.spicetify = {
  enable = true;
  theme = spicePkgs.themes.catppuccin;
  colorScheme = "mocha";

  enabledExtensions = with spicePkgs.extensions; [
    keyboardShortcut
    shuffle
    adblock
  ];
};
```

## Marketplace

The Marketplace is a **custom app** (not an extension) and goes in `enabledCustomApps`:

```nix
enabledCustomApps = with spicePkgs.apps; [
  marketplace
];
```

> **The Marketplace's install functionality does not work with this flake.** This is confirmed in the official spicetify-nix docs. The Marketplace installs things by writing files and calling `spicetify apply` at runtime — but the Nix store is read-only and there is no runtime spicetify CLI. It can be added for **browsing only**.

### Why `mkOutOfStoreSymlink` Won't Help

`mkOutOfStoreSymlink` is a Home Manager tool for symlinking mutable config files into `~/.config`. It has no effect here because:

- The `src` field for extensions/themes is typed as `pathInStore` — Nix rejects anything outside the store at evaluation time
- Spicetify's patching is a build-time `postInstall` step inside a derivation, not an activation-time file copy
- There is no mutable spicetify config directory to symlink into

### Workaround: Adding Marketplace Extensions Declaratively

For anything you find on the Marketplace that isn't already in `spicePkgs.extensions`, you can fetch it directly from its GitHub repo:

```nix
enabledExtensions = with spicePkgs.extensions; [
  shuffle
  adblock

  # Custom extension from GitHub (not packaged in spicetify-nix)
  {
    src = pkgs.fetchFromGitHub {
      owner = "OWNER";
      repo  = "REPO";
      rev   = "FULL_COMMIT_SHA";
      hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    name = "extensionName.js";
  }
];
```

If the `.js` file is inside a subdirectory of the repo (e.g. `/dist`, `/src`), append the subdir to the fetch result:

```nix
src = (pkgs.fetchFromGitHub {
  owner = "OWNER";
  repo  = "REPO";
  rev   = "FULL_COMMIT_SHA";
  hash  = "sha256-...";
}) + /dist;
```

To get the hash for a new repo:

```bash
nix-prefetch-url --unpack "https://github.com/OWNER/REPO/archive/FULL_SHA.tar.gz"
```

#### Workflow

1. Find the extension on the [Spicetify Marketplace](https://spicetify.app/docs/advanced-usage/extensions) or community repos
2. Check if it's already in [`spicePkgs.extensions`](https://github.com/Gerg-L/spicetify-nix/blob/master/docs/EXTENSIONS.md) — use it directly if so
3. If not, find its GitHub repo, pin a commit SHA, get the hash, and add it inline as shown above
4. Rebuild: `home-manager switch --flake .#dominic@nixos`

## Adding Themes

```nix
theme = spicePkgs.themes.catppuccin;
colorScheme = "mocha";
```

Full theme list: https://github.com/Gerg-L/spicetify-nix/blob/master/docs/THEMES.md

## Adding Built-in Extensions

```nix
enabledExtensions = with spicePkgs.extensions; [
  keyboardShortcut
  shuffle
  adblock
  fullAppDisplay
  hidePodcasts
  volumePercentage
];
```

Full extension list: https://github.com/Gerg-L/spicetify-nix/blob/master/docs/EXTENSIONS.md

## Adding Custom Apps

```nix
enabledCustomApps = with spicePkgs.apps; [
  lyricsPlus
  newReleases
];
```
