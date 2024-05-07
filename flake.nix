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
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, agenix, hyprland, ... } @ inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    packages.x86_64-linux.default = self.formatter.x86_64-linux;
    nixosConfigurations =
      let
        commonModules = [
          ./common-modules/nvidia.nix
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
        firewallModules = [
          ./hypervisors/hv-modules/hv-firewall.nix
        ];
        k3sModules = [
          ./hypervisors/hv-modules/hv-k3s.nix
        ];
        workstationModules = [
          hyprland.nixosModules.default
        ];
      in
      {
        hv-2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonModules ++ hypervisorModules ++ firewallModules ++ k3sModules ++ [
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
                  extraFlags = [ "--flannel-backend=none" "--disable-network-policy" ];
                };
              };
            })
          ];
        };
        # Add more hypervisor configurations as needed
      };
  };
}
