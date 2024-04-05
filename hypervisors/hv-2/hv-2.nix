{ modulesPath, config, lib, pkgs, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hv-2-disk-config.nix
  ];

  # Define the hostname
  networking.hostName = "hv-2";

  # Define the timezone
  time.timeZone = "America/Los_Angeles";

  # Networking configuration for systemd-networkd
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  systemd.network = {
    enable = true;

    # Define network devices including bond interfaces and VLANs
    netdevs = {
      # LACP bond configuration
      "bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad"; # LACP mode for bonding
          MIIMonitorSec = 100;
          UpDelaySec = 200;
          DownDelaySec = 200;
          TransmitHashPolicy = "layer2+3";
          LACPTransmitRate = "fast";
        };
      };

      # Active-backup bond configuration including bond0 and enp37s0
      "bond1" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond1";
        };
        bondConfig = {
          Mode = "active-backup";
          MIIMonitorSec = 100;
          PrimaryReselectPolicy = "always";
        };
      };

      # VLAN5 on top of the bond1
      "vlan5" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan5";
        };
        vlanConfig = {
          Id = 5;
          # Link = "bond1"; # Not allowed
        };
      };
    };

    networks = {
      "enp16s0f0" = {
        matchConfig.Name = "enp16s0f0";
        networkConfig.Bond = "bond0";
        networkConfig.DHCP = false;
        linkConfig.RequiredForOnline = "enslaved";
      };

      "enp16s0f1" = {
        matchConfig.Name = "enp16s0f1";
        networkConfig.Bond = "bond0";
        networkConfig.DHCP = false;
        linkConfig.RequiredForOnline = "enslaved";
      };

      "enp37s0" = {
        matchConfig.Name = "enp37s0";
        networkConfig.Bond = "bond1";
        networkConfig.DHCP = false;
        linkConfig.RequiredForOnline = "enslaved";
      };

      # Configuration for bond0 as part of bond1
      "bond0" = {
        matchConfig.Name = "bond0";
        networkConfig.Bond = "bond1";
        networkConfig.DHCP = false;
        linkConfig.RequiredForOnline = "enslaved";
      };

      # Bond1 interface configuration
      "bond1" = {
        matchConfig.Name = "bond1";
        networkConfig.Bridge = "br-vlan5"; # Attach bond1 to the bridge
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      # VLAN5 interface is now part of the bridge
      "vlan5" = {
        matchConfig.Name = "vlan5";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        networkConfig.Address = [ "10.173.5.70/24" ];
        networkConfig.Gateway = "10.173.5.1";
        networkConfig.DNS = [ "1.1.1.1" ];
        linkConfig.RequiredForOnline = "yes"; # The bridge itself needs to be online
      };
    };
  };

  # Hardware configuration
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
