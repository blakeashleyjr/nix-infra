let
  # Systems

  ## Users
  blake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK29aC0ZvTjltZcJkPHSGn01Zlhywr1QJZVtKQ8U3YU1 blake@ashleyjr.com";

  ## hypervisors
  hv-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOfPdPsDe6CaGfNRkiVovLLf4EHkY+XVjXtSgT8s7Ph  hv-2";

  ## workstations

  ## assignments
  users = [ blake ];
  hv = [ ];
  ws = [ ];
in
{
  "tailscale-authkey.age".publicKeys = hv ++ ws ++ users;
  "wan-gateway.age".publicKeys = hv ++ users;
  "public-ip-1.age".publicKeys = hv ++ users;
  "nextdns-config.age".publicKeys = hv ++ users;
  "nextdns-config-stamp.age".publicKeys = hv ++ users;
  "nextdns-config-ws.age".publicKeys = ws ++ users;
  "nextdns-config-stamp-ws.age".publicKeys = ws ++ users;
  # "k3s-token-1.age".publicKeys = hv ++ users;
}
