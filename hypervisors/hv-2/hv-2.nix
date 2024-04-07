{ modulesPath, config, lib, pkgs, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hv-2-disk-config.nix
  ];

  # Define the hostname
  networking.hostName = "hv-2";
  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
  };

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

      # VLAN2 on top of the bond1
      "vlan2" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan2";
        };
        vlanConfig = {
          Id = 2;
        };
      };

      # VLAN3 on top of the bond1
      "vlan3" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan3";
        };
        vlanConfig = {
          Id = 3;
        };
      };

      # VLAN4 on top of the bond1
      "vlan4" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan4";
        };
        vlanConfig = {
          Id = 4;
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
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
        vlan = [ "vlan5" ];
      };

      # VLAN2 WAN interface configuration
      "vlan2" = {
        matchConfig.Name = "vlan2";
        networkConfig.DHCP = true;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };

      # VLAN 3 LAN interface configuration
      "vlan3" = {
        matchConfig.Name = "vlan3";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };

      # VLAN4 interface configuration (Heartbeat network)
      "vlan4" = {
        matchConfig.Name = "vlan4";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        networkConfig.Gateway = "10.173.4.1";
        linkConfig.RequiredForOnline = "no";
        networkConfig.Address = [ "10.173.4.70/24" ];
      };

      # VLAN5 interface configuration (Management network)
      "vlan5" = {
        matchConfig.Name = "vlan5";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        networkConfig.Address = [ "10.173.5.70/24" ];
        networkConfig.Gateway = "10.173.5.1";
        networkConfig.DNS = [ "127.0.0.1:53" ];
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

  # Imperpance configuration
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /btrfs_tmp
    mount / /btrfs_tmp 
    if [[ -e /btrfs_tmp/@rootfs ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date "+%Y-%m-%d_%H-%M-%S")  # Correctly handled as a bash variable
      btrfs subvolume snapshot /btrfs_tmp/@rootfs "/btrfs_tmp/old_roots/@rootfs-$$timestamp"
    fi

    delete_subvolume_recursively() {
        local subvol="$$1"
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$subvol" | awk '{print $NF}'); do
            delete_subvolume_recursively "$subvol/$i"
        done
        btrfs subvolume delete "$subvol"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30 -type d); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/@rootfs  # Creates a new root subvolume for the upcoming boot
    umount /btrfs_tmp
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
