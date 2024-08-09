{ config, pkgs, ... }:
{
  users.users.blake = {
    isNormalUser = true;
    description = "Blake";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      firefox
      thunderbird
      vscode
      zellij
      zoom-us
      signal-desktop
      libreoffice-fresh
      fira-code
      gimp
      inkscape
      obs-studio
      mpv
      vlc
      zathura
      inkscape
      protonvpn-gui
      feh
      mullvad-vpn
      yt-dlp
      fzf
      alacritty
      keychain
      kubectl
      gnupg
      rofi
      teams-for-linux
      libsForQt5.okular
      # cheese
      # nemo
      filezilla
      mullvad-browser
      parsec-bin
      gdu
      glances
      gotop
      k9s
      lazydocker
      lazygit
      jq
      rsync
      vim
      nheko
      # gnome-calculator
      tor
      # Fish
      fishPlugins.tide
      vmware-horizon-client
      php83Packages.composer
      webex
      cobra-cli
      edgedb
      tree
      ncdu
      go
      php
      rclone
      age
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

  # # Pushes updates to dotfiles every 1 minutes
  # systemd.timers."update-dotfiles" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnBootSec = "1min";
  #     OnUnitActiveSec = "30min";
  #     Unit = "update-dotfiles.service";
  #   };
  # };

  # systemd.services."update-dotfiles" = {
  #   script = ''
  #     /run/current-system/sw/bin/fish /home/blake/scripts/update-dotfiles.fish
  #   '';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "blake";
  #   };
  # };


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


}
