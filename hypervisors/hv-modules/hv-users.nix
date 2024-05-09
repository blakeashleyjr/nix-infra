{ config, pkgs, ... }:
{
  users.users.serveradmin = {
    isNormalUser = true;
    description = "serveradmin";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "serveradmin" ];
    packages = with pkgs; [

    ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com" ];

  };

  # Define the serveradmin group
  users.groups.serveradmin = {
    gid = 1000;
  };

  programs.fish.enable = true;

}
