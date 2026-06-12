{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.aseprite ];

  xdg.mimeApps.defaultApplicationPackages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.aseprite ];
}
