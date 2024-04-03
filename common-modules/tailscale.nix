{ config, pkgs, ... }:
let
  # Reference the encrypted auth key
  tailscaleAuthKey = config.age.secrets.tailscale-authkey.path;
in
{
  # Ensure the age module and secrets are properly integrated
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
      # Wait for tailscaled to settle
      sleep 2

      # Check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ "$status" = "Running" ]; then
        exit 0
      fi

      # Otherwise authenticate with tailscale
      # Use the decrypted auth key from the Nix store
      ${tailscale}/bin/tailscale up --authkey $(cat ${tailscaleAuthKey})
    '';
  };
}
