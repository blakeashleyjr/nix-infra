{ config, pkgs, lib, ... }:

let
  isEnabled = config.tailscale.enable;
  age.secrets = {
    "tailscale-authkey".file = ../secrets/tailscale-authkey.age;
  };
in
{
  options.tailscale = {
    enable = lib.mkEnableOption "Tailscale service" // { default = true; };

    authKeyPath = lib.mkOption {
      type = lib.types.path;
      default = config.age.secrets.tailscale-authkey.path;
      description = "Path to the Tailscale authentication key secret.";
    };
    configureTailscale = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to configure Tailscale with additional arguments.";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Comma-separated routes to advertise over Tailscale.";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to advertise this node as an exit node.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos-CHANGE";
      description = "Hostname for this Tailscale node.";
    };

    acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to accept DNS configurations from Tailscale.";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to accept routes from Tailscale.";
    };

    authDns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to authenticate DNS with Tailscale.";
    };

    hostRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to add host routes with Tailscale.";
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable SSH on this Tailscale node.";
    };

    advertiseTags = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Tags to advertise over Tailscale, comma-separated.";
    };

    exitNode = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Specify the exit node for this Tailscale node.";
    };

    exitNodeAllowLANAccess = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow LAN access from this exit node.";
    };

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Specify the login server URL for Tailscale.";
    };

    netfilterMode = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Set netfilter mode for Tailscale.";
    };

    operator = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Specify the operator email for this Tailscale node.";
    };

    qr = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable QR code generation for Tailscale.";
    };

    shieldsUp = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable shields up mode in Tailscale, blocking all incoming connections.";
    };

    timeout = lib.mkOption {
      type = lib.types.str;
      default = "0s";
      description = "Set timeout for Tailscale operations.";
    };

    acceptRisk = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Acknowledge and accept the risk for specific Tailscale operations.";
    };

    forceReauth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force reauthentication with Tailscale.";
    };

    reset = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Reset the Tailscale node state.";
    };

    args = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional arguments to pass to Tailscale.";
    };

  };

  config = lib.mkIf isEnabled {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      after = [ "network-online.target" "tailscaled.service" ]; # Ensure tailscaled is started and network is online
      wants = [ "network-online.target" "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";

      script =
        let
          tailscaleAuthKey = config.tailscale.authKeyPath;
          optionalTailscaleConfig =
            if config.tailscale.configureTailscale then
              lib.strings.concatStringsSep " "
                (lib.attrsets.mapAttrsToList
                  (name: value:
                    let
                      toString = v: if v == true then "true" else if v == false then "false" else v;
                    in
                    if value == "" || value == false then ""
                    else "--${name}=${toString value}"
                  )
                  {
                    advertiseRoutes = config.tailscale.advertiseRoutes;
                    advertiseExitNode = config.tailscale.advertiseExitNode;
                    hostname = config.tailscale.hostname;
                    acceptDns = config.tailscale.acceptDns;
                    acceptRoutes = config.tailscale.acceptRoutes;
                    authDns = config.tailscale.authDns;
                    hostRoutes = config.tailscale.hostRoutes;
                    ssh = config.tailscale.ssh;
                    advertiseTags = config.tailscale.advertiseTags;
                    exitNode = config.tailscale.exitNode;
                    exitNodeAllowLANAccess = config.tailscale.exitNodeAllowLANAccess;
                    loginServer = config.tailscale.loginServer;
                    netfilterMode = config.tailscale.netfilterMode;
                    operator = config.tailscale.operator;
                    qr = config.tailscale.qr;
                    shieldsUp = config.tailscale.shieldsUp;
                    timeout = config.tailscale.timeout;
                    acceptRisk = config.tailscale.acceptRisk;
                    forceReauth = config.tailscale.forceReauth;
                    reset = config.tailscale.reset;
                  }
                )
            else "";
        in
        ''
          sleep 2
          status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
          if [ "$status" = "Running" ]; then
            exit 0
          fi
          ${pkgs.tailscale}/bin/tailscale up ${optionalTailscaleConfig} --authkey $(cat ${tailscaleAuthKey})
        '';
    };
  };
}
