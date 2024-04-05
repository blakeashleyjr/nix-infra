{
  description = "NixOS flake configuration for my entire infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, agenix, hyprland, ... } @ inputs: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    nixosConfigurations = {
      hv-2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hypervisors/hv-2/hv-2.nix
        ];
      };
      # Add more machine configurations as needed
    };
  };
}
