# ws-network.nix
{ config, lib, pkgs, ... }:

let
  # Use the secretActivationScript function
  nextdnsConfigWSSecret = config.secretActivationScript "nextdns-config-ws" config.age.secrets."nextdns-config-ws".path "/etc/dnscrypt-proxy2/nextdns-config-ws" "dnscrypt" "dnscrypt";
  nextdnsConfigWSStampSecret = config.secretActivationScript "nextdns-config-stamp-ws" config.age.secrets."nextdns-config-stamp-ws".path "/etc/dnscrypt-proxy2/nextdns-config-stamp-ws" "dnscrypt" "dnscrypt";
in
{
  system.activationScripts = {
    nextdnsConfigWSSecret.text = nextdnsConfigWSSecret;
    nextdnsConfigWSStampSecret.text = nextdnsConfigWSStampSecret;
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      server_names = [ "NextDNS-@secret@" ];  # Template placeholder
      listen_addresses = [ "[::1]:53" ];
      ipv6_servers = true;
      require_dnssec = true;

      static = {
        "NextDNS-@secret@" = {  # Template placeholder
          stamp = "@secret@";  # Template placeholder
        };
      };
    };
  };
}
