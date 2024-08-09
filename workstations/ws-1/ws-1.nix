{ config, lib, pkgs, modulesPath, ... }:

{
  # Version specification
  system.stateVersion = "23.11"; # Don't change

  networking.hostName = "ares-nix";
  networking.useDHCP = false;
  networking.interfaces.enp11s0f1.ipv4.addresses = [{ address = "10.0.2.51"; prefixLength = 24; }];
  networking.defaultGateway = "10.0.2.1";
  networking.nameservers = [ "127.0.0.1" "::1" ];


  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
    forceFullCompositionPipeline = true;
  };

  # Localization and timezone settings
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

}
