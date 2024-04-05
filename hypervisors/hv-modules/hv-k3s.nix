{ config, pkgs, lib, ... }@args:
let
  # Ensure `clusterInit` has a default value if not provided in `args`
  clusterInit = args.clusterInit or false; # Defaults to false if not defined

  # Now `clusterInit` is guaranteed to be defined, so we can safely use it
  optionalTokenConfig = if clusterInit then { } else { token = args.token; };

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
