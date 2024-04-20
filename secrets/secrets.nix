let
  # Systems

  ## Users
  blake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com";

  ## hypervisors
  hv-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFq0waQeGTownYGJtNHazTydCqSxlyMGh+pjsh8HHsL9 root@nixos";

  ## workstations

  ## assignments (make sure to add to the users/systems list below)
  users = [ blake ];
  hv = [ hv-2 ];
  ws = [ ];
in
{
  "tailscale-authkey.age".publicKeys = hv ++ ws ++ users;
  "wan-gateway.age".publicKeys = hv ++ users;
  "public-ip-1.age".publicKeys = hv ++ users;
  # "k3s-token-1.age".publicKeys = hv ++ users;
}

## Add all secrets to the secrets list in ./common-modules/system.nix
