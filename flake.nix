{
  description = "NixOS flake configuration for my entire infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix = {
      url = "github:ryantm/agenix";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
  };

  outputs = { self, nixpkgs, agenix, hyprland, disko, ... } @ inputs: {
    nixosConfigurations = 
      let

        # Import the secret activation module
        secretActivationModule = import ./common-modules/secret-activation.nix;

      
        commonModules = [
          ./common-modules/system.nix
          ./common-modules/tailscale.nix
          ./common-modules/security.nix
          ./common-modules/secret-activation.nix
          disko.nixosModules.disko
          agenix.nixosModules.default
        ];

        commonSecrets = [
          { age.secrets = {
              "tailscale-authkey".file = ./secrets/tailscale-authkey.age;
            };
          }
        ];

        hypervisorModules = [
          ./hypervisors/hv-modules/hv-users.nix
          ./hypervisors/hv-modules/hv-base.nix
        ];

        hypervisorNvidiaModules = [
          ./hypervisors/hv-modules/hv-nvidia.nix
        ];

        firewallModules = [
          ./hypervisors/hv-modules/hv-firewall.nix
        ];

        firewallSecrets = [
          { age.secrets = {
              "wan-gateway".file = ./secrets/wan-gateway.age;
              "public-ip-1".file = ./secrets/public-ip-1.age;
            };
          }
        ];

        k3sModules = [
          ./hypervisors/hv-modules/hv-k3s.nix
        ];

        workstationModules = [
          ./workstations/ws-modules/ws-users.nix
          ./workstations/ws-modules/ws-network.nix
          ./workstations/ws-modules/ws-desktop.nix
          ./workstations/ws-modules/ws-boot.nix
          ./workstations/ws-modules/ws-base.nix
          ./workstations/ws-modules/services/firefox.nix
          ./workstations/ws-modules/services/syncthing.nix
        ];

        workstationSecrets = [
          { age.secrets = {
              "nextdns-config-ws".file = ./secrets/nextdns-config-ws.age;
              "nextdns-config-stamp-ws".file = ./secrets/nextdns-config-stamp-ws.age;
            };
          }
        ];

        workstationNvidiaModules = [
          ./workstations/ws-modules/ws-nvidia.nix
        ];

      in
      {
        hv-2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = commonModules ++ commonSecrets ++ hypervisorModules ++ firewallModules ++ firewallSecrets ++ k3sModules ++ hypervisorNvidiaModules ++ [
            ./hypervisors/hv-2/hv-2.nix
            ({ pkgs, config, lib, ... }: {
              config = {
                hv-Firewall.vrrpPriority = {
                  WAN_VIP = 90;
                  LAN_VIP = 90;
                };
                tailscale = {
                  enable = true;
                  hostname = "hv-2";
                  ssh = true;
                  exitNode = true;
                  exitNodeAllowLANAccess = true;
                };
                k3s = {
                  enable = true;
                  role = "server";
                  clusterInit = true;
                  extraFlags = "--flannel-backend=none --disable-network-policy";
                };
              };
            })
          ];
        };

        ws-1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = commonModules ++ commonSecrets ++ workstationModules ++ workstationSecrets ++ [
            ./workstations/ws-1/ws-1.nix
            ./workstations/ws-1/ws-1-hardware.nix
            ({ pkgs, config, lib, ... }: {
              config = {
                tailscale = {
                  enable = true;
                  hostname = "ws-1";
                  ssh = true;
                  exitNode = true;
                  exitNodeAllowLANAccess = true;
                };
              };
            })
          ];
        };
      };
  };
}
