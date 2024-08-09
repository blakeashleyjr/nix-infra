{ config, lib, pkgs, inputs, ... } @ args:
let
  age.secrets = {
    "nextdns-config-ws".file = ../secrets/nextdns-config-ws.age;
    "nextdns-config-stamp-ws".file = ../secrets/nextdns-config-stamp-ws.age;
  };
  # Load secrets
  nextdnsConfigWSSecret = config.age.secrets."nextdns-config-ws".path;
  nextdnsConfigWSStampSecret = config.age.secrets."nextdns-config-stamp-ws".path;
in
{
  
  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  # DNS Config to Nextdns for now
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      server_names = [ "NextDNS-${nextdnsConfigWSSecret}" ];
      listen_addresses = [ "[::1]:53" ];
      ipv6_servers = true;
      require_dnssec = true;

      static = {
        "NextDNS-${nextdnsConfigWSSecret}" = {
          stamp = "${nextdnsConfigWSStampSecret}";
        };
      };
    };
  };
}
