{ pkgs, ... }:
{
  # nixd and nixfmt must be on the system PATH so the nix-ide extension can
  # find them. They cannot be installed only as Neovim extraPackages, which
  # places them in Neovim's private wrapper PATH only.
  home.packages = with pkgs; [
    nixd
    nixfmt
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # Theme — Catppuccin to match system theme
      catppuccin.catppuccin-vsc
      catppuccin.catppuccin-vsc-icons

      # Nix
      jnoortheen.nix-ide
      arrterian.nix-env-selector

      # Go
      golang.go

      # Python
      ms-python.python

      # Terraform / HCL
      hashicorp.terraform

      # Git
      eamodio.gitlens

      # Formatting
      esbenp.prettier-vscode

      # Shell
      timonwong.shellcheck
    ];

    profiles.default.userSettings = {
      # Font — matches MesloLGS Nerd Font used in alacritty
      "editor.fontFamily" = "'MesloLGS Nerd Font', 'monospace'";
      "editor.fontSize" = 14;
      "terminal.integrated.fontFamily" = "'MesloLGS Nerd Font'";
      "terminal.integrated.fontSize" = 13;

      # Editor behaviour
      "editor.tabSize" = 2;
      "editor.formatOnSave" = true;
      "editor.renderWhitespace" = "trailing";
      "editor.minimap.enabled" = false;

      # Catppuccin Mocha theme
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.iconTheme" = "catppuccin-mocha";

      # Nix language server
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";

      # Per-language formatters
      "[go]"."editor.defaultFormatter" = "golang.go";
      "[python]"."editor.defaultFormatter" = "ms-python.python";
      "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
  };
}
