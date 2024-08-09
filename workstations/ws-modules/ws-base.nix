{ config, pkgs, ... }:
{
  # Set bootloader limit
  boot.loader.systemd-boot.configurationLimit = 20;

  age.identityPaths = [ "/home/blake/.ssh/id_ed25519_flake_key" ];

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