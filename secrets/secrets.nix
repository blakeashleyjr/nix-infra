let
  # Systems

  ## Users
  blake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com";

  ## hypervisors
  hv-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUL878+MSi2Fk6xlhPVFmw+NMUeGNVr7M7wTTrzABHG root@nixos";

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
  "nextdns-config.age".publicKeys = hv ++ users;
  "nextdns-config-stamp.age".publicKeys = hv ++ users;
  # "nextdns-config-ws.age".publicKeys = ws ++ users;
  # "nextdns-config-stamp-ws.age".publicKeys = ws ++ users;
  # "k3s-token-1.age".publicKeys = hv ++ users;
}

## Add all secrets to the secrets list in ./common-modules/system.nix
