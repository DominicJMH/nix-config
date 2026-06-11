{
  inputs,
  hostname,
  nixosModules,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/programs/gaming"
    # "${nixosModules}/desktop/niri"
  ];

  # Enable GNOME desktop (default NixOS desktop)
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # Set hostname
  networking.hostName = hostname;

  # Fingerprint authentication. Followed this https://discourse.nixos.org/t/how-to-enable-fingerprint-authentication-in-terminal/65828
  services.tailscale.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    22
    80
    8080
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false; # key-only, more secure
  };

  systemd.tmpfiles.rules = [
    "d /var/www/dashboard 0755 dominic users -"
    "d /var/www/vnu-dashboard 0755 dominic users -"
  ];

  services.nginx = {
    enable = true;

    # existing dashboard
    virtualHosts."dashboard" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      root = "/var/www/dashboard";
      locations."/" = {
        index = "index.html";
      };
    };

    # second dashboard on port 8080
    virtualHosts."vnu-dashboard" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8080;
        }
      ];
      root = "/var/www/vnu-dashboard";
      locations."/" = {
        index = "index.html";
      };
    };
  };

  services.fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # Apps installed at system level so their .desktop files land in
  # /run/current-system/sw/share/applications (reliably in XDG_DATA_DIRS for GDM/GNOME)
  environment.systemPackages = with pkgs; [
    anytype
    discord
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
