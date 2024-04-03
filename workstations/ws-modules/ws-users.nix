{ config, pkgs, ... }:
{
  users.users.blake = {
    isNormalUser = true;
    description = "Blake";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [

    ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com" ];

  };

  programs.fish.enable = true;

  # Global Git configuration
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user = {
        name = "Blake Ashley";
        email = "blake@ashleyjr.com";
      };
      user.signingkey = "8BC22723817BF8279DFD338E0CB911997C0160D9";
      commit.gpgsign = true;
      init = {
        defaultBranch = "main";
      };
    };
  };

  # Gaming
  programs.java.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  };

  # Change wallpaper every 5 minutes
  systemd.timers."swww-random" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Unit = "swww-random.service";
    };
  };

  systemd.services."swww-random" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/set_random_wallpaper.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };

  # Pushes updates to second brain every 1 minutes
  systemd.timers."update-second-brain" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "update-second-brain.service";
    };
  };

  systemd.services."update-second-brain" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/update-second-brain.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };

  # Pushes updates to dotfiles every 1 minutes
  systemd.timers."update-dotfiles" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "update-dotfiles.service";
    };
  };

  systemd.services."update-dotfiles" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/update-dotfiles.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };


  #  # Update the system ever hour
  #   systemd.timers."update-system" = {
  #     wantedBy = [ "timers.target" ];
  #     timerConfig = {
  #       OnBootSec = "60min";
  #       OnUnitActiveSec = "60min";
  #       Unit = "update-system.service";
  #     };
  #   };

  #   systemd.services."update-system" = {
  #     script = ''
  #       /run/current-system/sw/bin/fish /home/blake/scripts/update-system.fish
  #     '';
  #     serviceConfig = {
  #       Type = "oneshot";
  #       User = "blake";
  #     };
  #   };


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
    pinentryFlavor = "gnome3"; # Choose the appropriate pinentry flavor
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };

}
