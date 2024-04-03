{ config, pkgs, ... }:
{
  users.users.serveradmin = {
    isNormalUser = true;
    description = "serveradmin";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [

    ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com" ];

  };

  programs.fish.enable = true;

}
