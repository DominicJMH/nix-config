{ nhModules, lib, pkgs, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/misc/gtk"
    "${nhModules}/programs/vscode"
    "${nhModules}/programs/blender"
    "${nhModules}/programs/godot"
    "${nhModules}/programs/aseprite"
    # "${nhModules}/desktop/niri"
  ];

  # Cursor theme for GNOME
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Yaru";
    package = pkgs.yaru-theme;
    size = 24;
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # Disable alacritty — using default GNOME terminal (GNOME Console) instead
  # programs.alacritty.enable = true; # re-enable to restore alacritty
  programs.alacritty.enable = lib.mkForce false;


  home.packages = [ pkgs.firefox ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
