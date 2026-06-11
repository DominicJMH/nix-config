{ pkgs, userConfig, ... }:
{
  # GameMode: auto-applies performance optimizations when games launch
  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 10;
      cpu = {
        governor = "performance";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };

  # Steam with gaming-specific environment
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    package = pkgs.steam.override {
      extraEnv = {
        AMD_VULKAN_ICD = "RADV";
      };
    };
  };

  # Prevent frame drops from split-lock exceptions triggered by EAC/games
  boot.kernelParams = [
    "split_lock_detect=off"
  ];

  # Lower audio latency for positional audio cues
  services.pipewire.extraConfig.pipewire."10-gaming" = {
    "context.properties" = {
      "default.clock.quantum" = 256;
      "default.clock.min-quantum" = 256;
    };
  };

  # Add gamemode group to user
  users.users.${userConfig.name}.extraGroups = [ "gamemode" ];

  # Lutris game launcher + Wine for Windows game compatibility
  environment.systemPackages = with pkgs; [
    lutris
    wineWow64Packages.stable
  ];

  # CoreCtrl: AMD GPU/CPU tuning (unlocks all power/clock controls)
  programs.corectrl.enable = true;
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xffffffff";
  };
}
