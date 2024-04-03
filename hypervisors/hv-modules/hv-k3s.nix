{ config, pkgs, lib, ... }@args:
let
  # Determine if token should be included in the configuration
  optionalTokenConfig = if args.clusterInit then { } else { token = args.token; };

in
{
  services.k3s = lib.recursiveUpdate
    {
      enable = true;
      role = args.role; # "server" or potentially "agent"
      # Always included settings
      inherit (args) serverAddr;
    }
    optionalTokenConfig;
}
