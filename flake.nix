{
  description = "NixOS flake configuration for my entire infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    # hyprland-contrib = {
    #   url = "github:hyprwm/contrib";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, disko, agenix, hyprland, ... } @ inputs: {
    nixosConfigurations = 
      # Define common modules
      let
        commonModules = [
          ./common-modules/system.nix
          ./common-modules/tailscale.nix
          ./common-modules/security.nix
          # ./secrets/secrets.nix
          disko.nixosModules.disko
          agenix.nixosModules.default
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
        k3sModules = [
          ./hypervisors/hv-modules/hv-k3s.nix
        ];
        workstationModules = [
          ./workstations/ws-modules/ws-users.nix
          ./workstations/ws-modules/ws-network.nix
          ./workstations/ws-modules/ws-desktop.nix
          ./workstations/ws-modules/ws-boot.nix
          ./workstations/ws-modules/ws-system.nix
          ./workstations/ws-modules/services/fail2ban.nix
          ./workstations/ws-modules/services/firefox.nix
          ./workstations/ws-modules/services/syncthing.nix
        ];
        workstationNvidiaModules = [
          ./workstations/ws-modules/ws-nvidia.nix
        ];
      in
      {
        hv-2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = commonModules ++ hypervisorModules ++ firewallModules ++ k3sModules ++ hypervisorNvidiaModules ++ [
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
          modules = commonModules ++ workstationModules ++ workstationModules ++ [
            ./workstations/ws-1/ws-1.nix
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
