{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.blender ];

  xdg.mimeApps.defaultApplicationPackages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.blender ];
}
