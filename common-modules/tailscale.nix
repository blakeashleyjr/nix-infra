{ config, pkgs, lib, ... }:
let
  tailscaleAuthKey = config.age.secrets.tailscale-authkey.path;

  # Merge user-specified args with defaults
  tailscaleArgs = {
    configureTailscale = false;
    advertiseRoutes = "";
    advertiseExitNode = false;
    hostname = "nixos-CHANGE";
    acceptDns = false; # I have had problems with this in the past
    acceptRoutes = false;
    authDns = false;
    hostRoutes = false;
    ssh = true;
    advertiseTags = "";
    exitNode = "";
    exitNodeAllowLANAccess = false;
    loginServer = "";
    netfilterMode = "";
    operator = "";
    qr = false;
    shieldsUp = false;
    # snatSubnetRoutes = true; 
    timeout = "0s";
    acceptRisk = "";
    forceReauth = false;
    reset = false;
  } // config.tailscale.args;

  optionalTailscaleConfig =
    if tailscaleArgs.configureTailscale then
      lib.strings.concatStringsSep " "
        (lib.attrsets.mapAttrsToList
          (name: value:
            let
              toString = v: if v == true then "true" else if v == false then "false" else v;
            in
            if value == "" || value == false then ""
            else "--${name}=${toString value}"
          )
          tailscaleArgs)
    else "";

in
{
  age.secrets.tailscale-authkey = {
    file = ../secrets/tailscale-authkey.age;
  };

  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      sleep 2
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ "$status" = "Running" ]; then
        exit 0
      fi
      ${tailscale}/bin/tailscale up ${optionalTailscaleConfig} --authkey $(cat ${tailscaleAuthKey})
    '';
  };
}
