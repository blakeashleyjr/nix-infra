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

  # Hardware

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/4cdc7bba-aea0-440d-aa82-b66af1e32115";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-62c74ef6-b4af-4e12-a927-dd77010680fe".device = "/dev/disk/by-uuid/62c74ef6-b4af-4e12-a927-dd77010680fe";

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/2EA0-8ABB";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
