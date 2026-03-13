{inputs, hostname, nixosModules, ...}:
{
  imports = [
     ./hardware-configuration.nix
     "${nixosModules}/common"
     "${nixosModules}/desktop/niri"
  ];

  networking.hostname = hostname;

  time.timeZone = "Asia/Dubai";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "25.05";
}
