{ config, lib, pkgs, secretActivationScript, ... } @ args:
let
  # Use the secretActivationScript function
  system.activationScripts.nextdnsConfigWSSecret = secretActivationScript "nextdns-config-ws" config.age.secrets."nextdns-config-ws".path "/etc/dnscrypt-proxy2/nextdns-config-ws" "dnscrypt" "dnscrypt";
  system.activationScripts.nextdnsConfigWSStampSecret = secretActivationScript "nextdns-config-stamp-ws" config.age.secrets."nextdns-config-stamp-ws".path "/etc/dnscrypt-proxy2/nextdns-config-stamp-ws" "dnscrypt" "dnscrypt";
in
{
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
