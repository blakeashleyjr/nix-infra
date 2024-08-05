{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.grub.useOSProber = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System update configuration
  system.autoUpgrade.enable = false;
  system.autoUpgrade.allowReboot = false;

  # Update the system ever hour
    systemd.timers."update-system" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "60min";
        OnUnitActiveSec = "60min";
        Unit = "update-system.service";
      };
    };

    systemd.services."update-system" = {
      script = ''
        /run/current-system/sw/bin/fish /home/blake/scripts/update-system.fish
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "blake";
      };
    };


}
