{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.aseprite ];

  xdg.mimeApps.defaultApplicationPackages = [ pkgs.aseprite ];
}
