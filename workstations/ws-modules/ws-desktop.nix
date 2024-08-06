{ config, pkgs, inputs, ... }:

{
  # Security settings
  security.pam.services.waylock = {
    text = "auth include login";
  };

  # Enable cache for Hyprland to speed up builds
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  # Hyprland configuration and package inclusion
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
  
  # System package inclusion for a comprehensive desktop environment
  environment.systemPackages = with pkgs; [
    rofi-wayland
    wlsunset
    wl-clipboard
    waybar
    libsForQt5.qt5ct
    # hyprland-protocols
    # hyprland-per-window-layout
    xdg-desktop-portal-hyprland
    nwg-displays
    grimblast
    pavucontrol
    swaylock
    swww
    swaynotificationcenter
    wlogout
    ulauncher
    kickoff
    gnome.gnome-clocks # World clock
  ];

  # X11 and desktop environment settings
  services = { 
    xserver = {
      enable = true;
      desktopManager.plasma5.enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
    displayManager.sddm = {
      enable = true;
      autoNumlock = true;
    };
    displayManager.defaultSession = "hyprland";
  };

  # Systemd service configuration for greetd
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Prevents errors from spamming on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Environment setup for greetd
  environment.etc."greetd/environments".text = ''
    Hyprland
    fish
    startplasma-wayland
    '';

  # Set environmental variables for session
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Printing, sound, and realtime audio processing services
  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.timers."random-wallpaper" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Unit = "random-wallpaper.service";
    };
  };

  systemd.services."random-wallpaper" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/set_random_wallpaper.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000/"
        "XDG_SESSION_TYPE=wayland"
        "DISPLAY=:1"
        "DESKTOP_SESSION=hyprland"
        "XDG_BACKEND=wayland"
        "XDG_SESSION_PATH=/org/freedesktop/DisplayManager/Session1"
        "XDG_SESSION_TYPE=wayland"
      ];
      User = "blake";
    };
    wantedBy = [ "default.target" ];
  };

 # Change Hyprland gaps every 30 minutes to protect oled
 systemd.timers."gaps-random" = {
   wantedBy = [ "timers.target" ];
   timerConfig = {
     OnBootSec = "30min";
     OnUnitActiveSec = "30min";
     Unit = "gaps-random.service";
   };
 };

 systemd.services."gaps-random" = {
   script = ''
     /run/current-system/sw/bin/fish /home/blake/scripts/set_random_gaps.fish
   '';
   serviceConfig = {
     Type = "oneshot";
     User = "blake";
   };
 };
  # Enable and configure the GPG agent
  programs.gnupg.agent = {
    enable = true;
    settings = {
      default-cache-ttl = 86400;
      max-cache-ttl = 86400;
    };
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };

}
