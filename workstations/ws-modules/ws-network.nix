# "nextdns-config-ws.age".publicKeys = ws ++ users;
# "nextdns-config-stamp-ws.age".publicKeys = ws ++ users;
{ config, lib, pkgs, ... } @ args:
let
  # Load secrets
  nextdnsConfigWSSecret = config.age.secrets."nextdns-config-ws".path;
  nextdnsConfigWSStampSecret = config.age.secrets."nextdns-config-stamp-ws".path;
in
{
  age.secrets = {
    "nextdns-config-ws" = { file = ../../secrets/nextdns-config-ws.age; };
    "nextdns-config-stamp-ws" = { file = ../../secrets/nextdns-config-stamp-ws.age; };
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
          stamp = nextdnsConfigStampWSSecret;
        };
      };
    };
  };
}
