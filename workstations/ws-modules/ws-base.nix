{ config, pkgs, ... }:
{
  # Set bootloader limit
  boot.loader.systemd-boot.configurationLimit = 20;

  virtualisation.docker = {
    enable = true;
		enableOnBoot = true;
		# enableNvidia = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon = {
        settings = {
          dns = [ "1.1.1.1" "1.0.0.1" ];
        };
    };
    };

  };
}