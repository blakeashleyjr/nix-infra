{ config, lib, pkgs, ... }:

let
  cfg = config.services.keepalived;
  wanGatewayPath = config.hv-Firewall.wanGatewayPath;
  
  # Scripts to dynamically adjust the default gateway using the secret
  scriptTemplate = name: command: pkgs.writeScript "${name}.sh" ''
    #!/bin/sh
    WAN_GATEWAY_IP=$(cat ${wanGatewayPath})
    ip route ${command} default via $WAN_GATEWAY_IP
  '';

  # Generate the full path to the scripts as strings
  addGatewayScriptPath = "/run/agenix/add-gateway.sh";
  delGatewayScriptPath = "/run/agenix/del-gateway.sh";

in
{
  # Define custom options for this module
  options.hv-Firewall = {
    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "vlan2";
      description = "WAN interface for the firewall.";
    };
    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "vlan3";
      description = "LAN interface for the firewall.";
    };
    wanGatewayPath = lib.mkOption {
      type = lib.types.path;
      default = config.age.secrets."wan-gateway".path;
      description = "Path to the WAN gateway secret.";
    };
    public-ip-1Path = lib.mkOption {
      type = lib.types.path;
      default = config.age.secrets."public-ip-1".path;
      description = "Path to the public IP 1 secret.";
    };
    nextdns-config-stampPath = lib.mkOption {
      type = lib.types.path;
      default = config.age.secrets."nextdns-config-stamp".path;
      description = "Path to the NextDNS configuration stamp secret.";
    };
    dnsForwardingAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.0/8" "192.168.0.0/24" ];
      description = "DNS forwarding addresses.";
    };
    sourceNatNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.0/8" ];
      description = "Networks for source NAT.";
    };
    vrrpInterface = lib.mkOption {
      type = lib.types.str;
      default = "vlan4";
      description = "VRRP interface.";
    };
    vrrpIps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          ip = lib.mkOption {
            type = lib.types.str;
            description = "IP address.";
          };
          dev = lib.mkOption {
            type = lib.types.str;
            description = "Device.";
          };
        };
      });
      default = [
        { ip = config.age.secrets."public-ip-1".path; dev = "vlan2"; } # WAN VIP
        { ip = "10.173.3.3/24"; dev = "vlan3"; } # LAN VIP
      ];
      description = "VRRP IPs configuration.";
    };
    vrrpPriority = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { WAN_VIP = 0; LAN_VIP = 0; };
      description = "VRRP priority settings.";
    };
  };

  # Use the options
  config = {
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
            iifname "${config.hv-Firewall.lanInterface}" ip saddr { ${lib.concatStringsSep ", " config.hv-Firewall.dnsForwardingAddresses} } udp dport 53 accept;
            iifname "${config.hv-Firewall.wanInterface}" drop;
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
              ip saddr ${network} oifname "${config.hv-Firewall.wanInterface}" masquerade;
            }
          '')
          config.hv-Firewall.sourceNatNetworks;
      };
    };

    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        server_names = [ "NextDNS-${config.age.secrets."nextdns-config".path}" ];
        listen_addresses = [ "[::1]:53" ];
        ipv6_servers = true;
        require_dnssec = true;
        static = {
          "NextDNS-${config.age.secrets."nextdns-config".path}" = {
            stamp = config.age.secrets."nextdns-config-stamp".path;
          };
        };
      };
    };


    services.keepalived.enable = true;

    services.keepalived.vrrpScripts = {
      add_default_gw = {
        script = "${pkgs.coreutils}/bin/sh ${addGatewayScriptPath}";
        interval = 1;
        weight = 10;
      };
      del_default_gw = {
        script = "${pkgs.coreutils}/bin/sh ${delGatewayScriptPath}";
        interval = 1;
        weight = -10;
      };
    };

    services.keepalived.vrrpInstances = {
      WAN_VIP = {
        interface = config.hv-Firewall.vrrpInterface;
        state = "BACKUP";
        virtualRouterId = 51;
        priority = config.hv-Firewall.vrrpPriority.WAN_VIP;
        virtualIps = builtins.map (ip: { addr = ip.ip; dev = ip.dev; }) config.hv-Firewall.vrrpIps;
        trackScripts = [ "add_default_gw" "del_default_gw" ];
      };
      LAN_VIP = {
        interface = config.hv-Firewall.vrrpInterface;
        state = "BACKUP";
        virtualRouterId = 52;
        priority = config.hv-Firewall.vrrpPriority.LAN_VIP;
        virtualIps = builtins.map (ip: { addr = ip.ip; dev = ip.dev; }) (lib.filter (ip: ip.dev == config.hv-Firewall.lanInterface) config.hv-Firewall.vrrpIps);
      };
    };

    # Adjust kernel sysctl settings
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;
    };

    # Adjust assertions to use the custom options
    assertions = [
      {
        assertion = config.hv-Firewall.vrrpPriority.WAN_VIP != 0;
        message = "vrrpPriority.WAN_VIP must be set to a non-zero value.";
      }
      {
        assertion = config.hv-Firewall.vrrpPriority.LAN_VIP != 0;
        message = "vrrpPriority.LAN_VIP must be set to a non-zero value.";
      }
    ];

  # Use environment.etc to place the scripts at the specific path
  environment.etc."agenix/add-gateway.sh".source = pkgs.writeScript "add-gateway.sh" ''
    #!/bin/sh
    WAN_GATEWAY_IP=$(cat ${wanGatewayPath})
    ip route add default via $WAN_GATEWAY_IP
  '';
  environment.etc."agenix/del-gateway.sh".source = pkgs.writeScript "del-gateway.sh" ''
    #!/bin/sh
    WAN_GATEWAY_IP=$(cat ${wanGatewayPath})
    ip route del default via $WAN_GATEWAY_IP
  '';
};
}
