{ nhModules, pkgs, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/firefox"
    "${nhModules}/programs/input-leap"
    "${nhModules}/programs/zoxide"
    "${nhModules}/programs/vscode"
    "${nhModules}/programs/blender"
    "${nhModules}/programs/godot"
    "${nhModules}/programs/aseprite"
    "${nhModules}/programs/spicetify"
  ];

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    vlc
    lua
    love
  ];

  home.stateVersion = "26.05";
}
