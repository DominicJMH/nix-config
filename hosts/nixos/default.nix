{
  inputs,
  hostname,
  nixosModules,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    "${nixosModules}/common"
    # "${nixosModules}/desktop/niri"
  ];

  # Enable GNOME desktop (default NixOS desktop)
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # Set hostname
  networking.hostName = hostname;

  # Fingerprint authentication
  services.fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
