{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.godot_4 ];

  xdg.mimeApps.defaultApplicationPackages = [ pkgs.godot_4 ];
}
