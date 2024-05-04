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
    dhcpcd.enable = false;
    useNetworkd = true;
  };

  # Define the timezone
  time.timeZone = "America/Los_Angeles";

  # Networking configuration for systemd-networkd
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

  systemd.network = {
    enable = true;

    netdevs = {
      ## LACP bond (primary)
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

      ## VLAN devices (on top of bond0)
      "10-vlan-wan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan-wan";
        };
        vlanConfig = {
          Id = 2;
        };
      };

      "10-vlan-lan" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan-lan";
        };
        vlanConfig = {
          Id = 3;
        };
      };

      "10-vlan-heartbeat" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan-heartbeat";
        };
        vlanConfig = {
          Id = 4;
        };
      };

      "10-vlan-hypervisor" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vlan-hypervisor";
        };
        vlanConfig = {
          Id = 5;
        };
      };

      ## Bridges for each VLAN
      "10-br-wan" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-wan";
        };
      };

      "10-br-lan" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-lan";
        };
      };

      "10-br-heartbeat" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-heartbeat";
        };
      };

      "10-br-hypervisor" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-hypervisor";
        };
      };
    };

    networks = {
      "20-vlan-to-bond0" = {
        matchConfig.Name = "bond0";
        networkConfig.VLAN = [ "vlan-wan" "vlan-lan" "vlan-heartbeat" "vlan-hypervisor" ];
        # networkConfig.Metric = 100;
      };

      "20-vlan-br-wan" = {
        matchConfig.Name = "vlan-wan";
        networkConfig.Bridge = "br-wan";
      };

      "20-vlan-br-lan" = {
        matchConfig.Name = "vlan-lan";
        networkConfig.Bridge = "br-lan";
      };

      "20-vlan-br-heartbeat" = {
        matchConfig.Name = "vlan-heartbeat";
        networkConfig.Bridge = "br-heartbeat";
      };

      "20-vlan-br-hypervisor" = {
        matchConfig.Name = "vlan-hypervisor";
        networkConfig.Bridge = "br-hypervisor";
      };

      "30-br-wan" = {
        matchConfig.Name = "br-wan";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };

      "30-br-lan" = {
        matchConfig.Name = "br-lan";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };

      # "30-br-heartbeat" = {
      #   matchConfig.Name = "br-heartbeat";
      #   networkConfig.DHCP = false;
      #   networkConfig.LinkLocalAddressing = "no";
      #   networkConfig.Gateway = "10.173.4.1";
      #   linkConfig.RequiredForOnline = "no";
      #   networkConfig.Address = [ "10.173.4.70/24" ];
      # };

      "30-br-hypervisor" = {
        matchConfig.Name = "br-hypervisor";
        networkConfig.DHCP = false;
        networkConfig.LinkLocalAddressing = "no";
        networkConfig.Address = [ "10.173.5.70/24" ];
        networkConfig.Gateway = "10.173.5.1";
        networkConfig.DNS = [ "127.0.0.1:53" ];
        linkConfig.RequiredForOnline = "yes";
      };

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

      # "enp37s0" = {
      #   matchConfig.Name = "enp37s0";
      #   networkConfig.DHCP = false;
      #   networkConfig.Address = [ "10.173.6.70/24" ]; # Replace with actual IP
      #   networkConfig.Gateway = "10.173.6.1"; # Replace with actual gateway
      #   networkConfig.DNS = [ "127.0.0.1:53" ];
      #   linkConfig.RequiredForOnline = "yes";
      #   networkConfig.Metric = 200;
      # };

      bond0 = {
        matchConfig.Name = "bond0";
        networkConfig.DHCP = false;
        networkConfig = {
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "carrier";
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
