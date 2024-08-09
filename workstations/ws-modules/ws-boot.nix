{ config, pkgs, ... }:
{

  # # Update the system ever hour
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
