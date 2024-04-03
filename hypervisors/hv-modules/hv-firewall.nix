{ config, lib, pkgs, ... } @ args:
let
  # References to secrets' paths
  wanGatewaySecret = config.age.secrets."wan-gateway".path;
  nextdnsConfigSecret = config.age.secrets."nextdns-config".path;
  nextdnsConfigStampSecret = config.age.secrets."nextdns-config-stamp".path;
  publicIp1Secret = config.age.secrets."public-ip-1".path;

  defaultCfg = {
    wanInterface = "vlan2";
    lanInterface = "vlan3";
    wanGatewayPath = wanGatewaySecret;
    dnsForwardingAddresses = [ "10.0.0.0/8" "192.168.0.0/24" ];
    sourceNatNetworks = [ "10.0.0.0/8" ];
    vrrpInterface = "vlan4";
    vrrpIps = [
      { ip = publicIp1Secret; dev = "vlan2"; } # WAN VIP
      { ip = "10.173.3.3/24"; dev = "vlan3"; } # LAN VIP
    ];
    vrrpPriority = {
      WAN_VIP = 0;
      LAN_VIP = 0;
    };
  };

  cfg = lib.recursiveUpdate defaultCfg (args.specialArgs or { });
in
{
  age.secrets = {
    "wan-gateway" = { file = ../../secrets/wan-gateway.age; };
    "nextdns-config" = { file = ../../secrets/nextdns-config.age; };
    "nextdns-config-stamp" = { file = ../../secrets/nextdns-config-stamp.age; };
    "public-ip-1" = { file = ../../secrets/public-ip-1.age; };
  };

  networking.nftables.enable = true;

  networking.nftables.tables = {
    filter = {
      name = "filter";
      family = "ip";
      enable = true;
      content = ''
        chain input {
          type filter hook input priority 0; 
          ct state {established, related} accept;
          iifname "${cfg.lanInterface}" ip saddr { ${lib.concatStringsSep ", " cfg.dnsForwardingAddresses} } udp dport 53 accept;
          iifname "${cfg.wanInterface}" drop;
        }
        chain forward {
          type filter hook forward priority 0; 
          policy accept;
        }
        chain output {
          type filter hook output priority 0; 
          policy accept;
        }
      '';
    };
    nat = {
      name = "nat";
      family = "ip";
      enable = true;
      content = lib.concatMapStringsSep "\n"
        (network: ''
          chain postrouting {
            type nat hook postrouting priority srcnat; 
            ip saddr ${network} oifname "${cfg.wanInterface}" masquerade;
          }
        '')
        cfg.sourceNatNetworks;
    };
  };

  # DNS Config to Nextdns for now
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      server_names = [ "NextDNS-${nextdnsConfigSecret}" ];
      listen_addresses = [ "[::1]:53" ];
      ipv6_servers = true;
      require_dnssec = true;

      static = {
        "NextDNS-${nextdnsConfigSecret}" = {
          stamp = nextdnsConfigStampSecret;
        };
      };
    };
  };

  services.keepalived.enable = true;

  services.keepalived.vrrpInstances.WAN_VIP = {
    interface = cfg.vrrpInterface;
    state = "BACKUP";
    virtualRouterId = 51;
    priority = cfg.vrrpPriority.WAN_VIP;
    virtualIps = map (ip: { addr = ip.ipPath or ip.ip; dev = ip.dev; }) cfg.vrrpIps;
  };


  services.keepalived.vrrpInstances.LAN_VIP = {
    interface = cfg.vrrpInterface;
    state = "BACKUP";
    virtualRouterId = 52;
    priority = cfg.vrrpPriority.LAN_VIP;
    virtualIps = map (ip: { addr = ip.ip; dev = ip.dev; }) (lib.filter (ip: ip.dev == cfg.lanInterface) cfg.vrrpIps);
  };


  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;
  };

  # Assertions
  assertions = [
    {
      assertion = cfg.vrrpPriority.WAN_VIP != 0;
      message = "vrrpPriority.WAN_VIP must be set to a non-zero value.";
    }
    {
      assertion = cfg.vrrpPriority.LAN_VIP != 0;
      message = "vrrpPriority.LAN_VIP must be set to a non-zero value.";
    }
  ];
}

