{ modulesPath, config, lib, pkgs, ... }: {
  imports = [
    # Import the configuration for the disk
    ./hv-2-disk-config.nix

    # Common modules
    ../../common-modules/nvidia.nix
    ../../common-modules/system.nix
    ../../common-modules/tailscale.nix

    # Common modules
    ../../inputs/agenix.nixosModules.default
    ../../inputs/disko.nixosModules.disko

    # Hypervisor modules
    ../hypervisors/hv-modules/hv-users.nix
    ../hypervisors/hv-modules/hv-base.nix

    # Make this system a firewall
    ../hypervisors/hv-modules/hv-firewall.nix

    # Make this system a k3s server
    ../hypervisors/hv-modules/hv-k3s.nix
  ];

  # Machine-specific settings
  services.k3s = {
    role = "server";
    clusterInit = true;
    serverAddr = "10.173.5.70";
  };

  # Example: Define vrrpPriority directly in this file
  networking.vrrpPriority = {
    WAN_VIP = 100;
    LAN_VIP = 100;
  };
  
  # Define the hostname
  networking.hostName = "hv-2";

  # Define the timezone
  time.timeZone = "America/Los_Angeles";

  # Networking configuration for systemd-networkd
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  systemd.network = {
    enable = true;

    netdevs = {
      "bond0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "802.3ad";
          MIIMonitorSec = 100;
          UpDelaySec = 200;
          DownDelaySec = 200;
          TransmitHashPolicy = "layer2+3";
          LACPTransmitRate = "fast";
        };
      };
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
      "br-vlan5" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-vlan5";
        };
        # bridgeConfig = {
        #   VLANFiltering = true;
        # };
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
      "bond1" = {
        matchConfig.Name = "bond1";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };
      "br-vlan5" = {
        matchConfig.Name = "br-vlan5";
        networkConfig.DHCP = false;
        networkConfig.Address = [ "10.173.5.70/24" ];
        networkConfig.Gateway = "10.173.5.1";
        networkConfig.DNS = [ "1.1.1.1" ];
        networkConfig.VLAN = [
          { Id = 5; Link = "bond1"; }
        ];
        linkConfig.RequiredForOnline = "yes";
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
