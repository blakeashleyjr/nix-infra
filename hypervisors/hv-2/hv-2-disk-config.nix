{ lib, ... }:
let
  # Shared Variables
  diskDevice = "/dev/nvme0n1";
  rootPartition = "${diskDevice}p2"; # Assuming partition 2 for root

  # DisKo Configuration
  diskoConfig = {
    disko.devices = {
      disk = {
        vdb = {
          type = "disk";
          device = diskDevice;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                end = "-20G";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  subvolumes = {
                    "/rootfs" = { mountpoint = "/"; };
                    "/home" = {
                      mountOptions = [ "compress=zstd" ];
                      mountpoint = "/home";
                    };
                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
                    };
                  };
                };
              };
              plainSwap = {
                size = "100%";
                content = { type = "swap"; };
              };
            };
          };
        };
      };
    };
  };

  bootConfig = {
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /btrfs_tmp
      mount ${rootPartition} /btrfs_tmp  # Dynamically uses the rootPartition variable
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
  };

in
{
  # Incorporate both `diskoConfig` and `bootConfig` into your NixOS configuration
  imports = [ diskoConfig bootConfig ];
}

