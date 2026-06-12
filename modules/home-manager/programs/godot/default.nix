{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.godot_4 ];

  xdg.mimeApps.defaultApplicationPackages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.godot_4 ];
}
