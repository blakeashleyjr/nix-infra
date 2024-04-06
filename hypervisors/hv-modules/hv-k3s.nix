{ config, lib, ... }:

with lib;

let
  cfg = config.services.k3s;
in
{
  # Ensure the k3s service is enabled and configure it according to your requirements
  config = mkIf cfg.enable {
    # Directly set values for the k3s service; no need to declare options again
    services.k3s = {
      role = cfg.role;
      serverAddr = cfg.serverAddr;

      # Conditionally include the token if clusterInit is false and token is provided
      token = mkIf (!cfg.clusterInit && cfg.token != null) cfg.token;

      # Directly use the `extraFlags` from the configuration
      extraFlags = optional (cfg.extraFlags != [ ]) cfg.extraFlags;
    };
  };
}
