let
  # Systems

  ## Users
  blake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com";

  ## hypervisors
  hv-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFq0waQeGTownYGJtNHazTydCqSxlyMGh+pjsh8HHsL9 root@nixos";

  ## workstations

  ## workstations
  ws-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 ws-1@workstation";
  users = [ blake ];
  hv = [ hv-2 ];
  ws = [ ws-1 ];
in
{
  "tailscale-authkey.age".publicKeys = hv ++ ws ++ users;
  "wan-gateway.age".publicKeys = hv ++ users;
  "public-ip-1.age".publicKeys = hv ++ users;
  "nextdns-config-ws.age".publicKeys = ws ++ users;
  "nextdns-config-stamp-ws.age".publicKeys = ws ++ users;
}

## Add all secrets to the secrets list in ./common-modules/system.nix
