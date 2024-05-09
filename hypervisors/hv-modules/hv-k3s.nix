{ config, pkgs, lib, ... }:

let
  isEnabled = config.k3s.enable;
in
{
  options.k3s = {
    enable = lib.mkEnableOption "Enable k3s service";

    role = lib.mkOption {
      type = lib.types.str;
      default = "agent";
      description = "Role of the k3s node (server or agent).";
    };

    serverAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Address of the k3s server (for agent role).";
    };

    token = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Token for joining the k3s cluster.";
    };

    clusterInit = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to initialize the k3s cluster.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Extra flags to pass to the k3s binary.";
    };
  };

  config = lib.mkIf isEnabled {
    services.k3s = {
      enable = true;
      role = config.k3s.role;
      serverAddr = lib.mkIf (!config.k3s.clusterInit) config.k3s.serverAddr;
      token = lib.mkIf (!config.k3s.clusterInit && config.k3s.token != null) config.k3s.token;
      extraFlags = config.k3s.extraFlags;
    };
  };
}
