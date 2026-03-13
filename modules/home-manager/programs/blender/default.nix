{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.blender ];

  xdg.mimeApps.defaultApplicationPackages = [ pkgs.blender ];
}
