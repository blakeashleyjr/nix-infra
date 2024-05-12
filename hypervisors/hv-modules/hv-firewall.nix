{ config, lib, pkgs, ... }:

let
  cfg = config.services.keepalived;
  wanGatewayPath = config.age.secrets."wan-gateway".path;
  publicIp1Path = config.age.secrets."public-ip-1".path;

  secretEnvFile = "/run/keepalived/secrets";

  scriptTemplate = name: command: pkgs.writeScript "${name}.sh" ''
    #!/bin/sh
    IP=$WAN_GATEWAY_IP
    ip route ${command} default via $IP
  '';

  addGatewayScriptPath = "/run/keepalived/add-gateway.sh";
  delGatewayScriptPath = "/run/keepalived/del-gateway.sh";
in
{
  options.hv-Firewall = {
    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "br-wan";
      description = "WAN interface for the firewall.";
    };
    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "br-lan";
      description = "LAN interface for the firewall.";
    };
    heartbeatInterface = lib.mkOption {
      type = lib.types.str;
      default = "br-heartbeat";
      description = "Heartbeat interface for the firewall.";
    };
    wanGatewayPath = lib.mkOption {
      type = lib.types.path;
      default = wanGatewayPath;
      description = "Path to the WAN gateway secret.";
    };
    public-ip-1Path = lib.mkOption {
      type = lib.types.path;
      default = publicIp1Path;
      description = "Path to the public IP 1 secret.";
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
        { ip = "$PUBLIC_IP_1"; dev = "br-wan"; } # WAN VIP
        { ip = "10.173.3.3/24"; dev = "br-lan"; } # LAN VIP
      ];
      description = "VRRP IPs configuration.";
    };
    vrrpPriority = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { WAN_VIP = 0; LAN_VIP = 0; };
      description = "VRRP priority settings.";
    };
    trustedSshSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.0/8" ];
      description = "Trusted IP addresses or networks for SSH access.";
    };
    trustedIcmpSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.0.0.0/8" ];
      description = "Trusted IP addresses or networks for ICMP echo requests (ping).";
    };
  };

  config = {
    networking.nftables.enable = true;
    networking.nftables.tables = {
      filter = {
        name = "filter";
        family = "ip";
        enable = true;
        content = ''
          # Set default policies to drop for all chains
          chain input {
            type filter hook input priority 0;
            policy drop;
          }
          chain forward {
            type filter hook forward priority 0;
            policy drop;
          }
          chain output {
            type filter hook output priority 0;
            policy accept;
          }

          # Input chain rules
          chain input {
            # Allow all traffic on the loopback interface
            iifname "lo" accept;

            # Allow Kubernetes API server access from local network or localhost
            iifname "${config.hv-Firewall.lanInterface}"
            tcp dport { 6443, 6444 } accept;

            # Allow established and related connections
            ct state {established, related} accept;

            # Allow DNS queries from specified LAN DNS forwarders to the DNS server
            iifname "${config.hv-Firewall.lanInterface}" ip saddr { ${lib.concatStringsSep ", " config.hv-Firewall.dnsForwardingAddresses} } udp dport 53 accept;

            # Allow SSH access from trusted IP addresses or networks
            ip saddr { ${lib.concatStringsSep ", " config.hv-Firewall.trustedSshSources} } tcp dport 22 accept;

            # Allow ICMP echo requests (ping) from trusted IP addresses or networks
            ip saddr { ${lib.concatStringsSep ", " config.hv-Firewall.trustedIcmpSources} } icmp type echo-request accept;

            # Allow incoming HTTP/HTTPS traffic from the local network
            iifname "${config.hv-Firewall.lanInterface}" tcp dport { 80, 443 } accept;
            tcp sport { 80, 443 } accept;
            
          }

          # Output chain rules
          chain output {
            # Allow all outgoing traffic
            accept;

            # Specifically allow outgoing DNS
            udp dport 53 accept;

            # Specifically allow outgoing HTTP/HTTPS for updates
            tcp dport { 80, 443 } accept;

            log prefix "nftables-dropped: " drop;
          }

          # Forward chain rules
          chain forward {
            # Only allow forwarding of established or related connections
            ct state {established, related} accept;
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
        server_names = [ "NextDNS-f33fea" ];
        listen_addresses = [ "[::1]:53" ];
        ipv6_servers = true;
        require_dnssec = true;
        bootstrap_resolvers = [ "9.9.9.11:53" "1.1.1.1:53" ];
        log_files_max_size = 10;
        log_files_max_age = 7;
        log_files_max_backups = 1;
        cache = true;
        cache_size = 4096;
        cache_min_ttl = 2400;
        cache_max_ttl = 86400;
        cache_neg_min_ttl = 60;
        cache_neg_max_ttl = 600;
        static = {
          "NextDNS-f33fea" = {
            stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2YzM2ZlYQ";
          };
        };
      };
    };

    systemd.services.dnscrypt-proxy2.serviceConfig = {
      StateDirectory = "dnscrypt-proxy";
    };

    users.users.keepalived_script = {
      isSystemUser = true;
      description = "User for Keepalived scripts";
      group = "keepalived_script";
    };

    users.groups.keepalived_script = { };

    systemd.services.keepalived-secrets = {
      description = "Prepare secrets for Keepalived";
      before = [ "keepalived.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = pkgs.writeScript "keepalived-secrets.sh" ''
          #!/bin/sh
          mkdir -p /run/keepalived
          chown keepalived_script:keepalived_script /run/keepalived
          chmod 0700 /run/keepalived
          echo "PUBLIC_IP_1=$(cat ${publicIp1Path})" > ${secretEnvFile}
          chown keepalived_script:keepalived_script ${secretEnvFile}
          chmod 0600 ${secretEnvFile}
        '';
      };
    };

    systemd.services.keepalived-scripts = {
      description = "Prepare scripts for Keepalived";
      before = [ "keepalived.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = pkgs.writeScript "keepalived-scripts.sh" ''
          #!/bin/sh
          mkdir -p /run/keepalived
          chown keepalived_script:keepalived_script /run/keepalived
          chmod 0750 /run/keepalived
          echo '${pkgs.writeScript "add-gateway.sh" ''
            #!/bin/sh
            WAN_GATEWAY_IP=$(cat ${wanGatewayPath})  
            ip route add default via $WAN_GATEWAY_IP
          ''}' > ${addGatewayScriptPath}
          echo '${pkgs.writeScript "del-gateway.sh" ''
            #!/bin/sh  
            WAN_GATEWAY_IP=$(cat ${wanGatewayPath})
            ip route del default via $WAN_GATEWAY_IP  
          ''}' > ${delGatewayScriptPath}
          chown keepalived_script:keepalived_script ${addGatewayScriptPath} ${delGatewayScriptPath}
          chmod 0550 ${addGatewayScriptPath} ${delGatewayScriptPath}
        '';
      };
    };
    systemd.services.keepalived = {
      requires = [ "network-online.target" ];
      after = [ "network-online.target" "network-pre.target" "br-heartbeat.service" ];
      # serviceConfig = {
      #   User = "keepalived_script";
      #   Group = "keepalived_script";
      # };
    };

    services.keepalived = {
      enable = true;
      secretFile = secretEnvFile;
      enableScriptSecurity = true;
      vrrpScripts = {
        add_default_gw = {
          script = addGatewayScriptPath;
          interval = 1;
          weight = 10;
        };
        del_default_gw = {
          script = delGatewayScriptPath;
          interval = 1;
          weight = -10;
        };
      };
      vrrpInstances = {
        WAN_VIP = {
          interface = config.hv-Firewall.heartbeatInterface;
          state = "BACKUP";
          virtualRouterId = 51;
          priority = config.hv-Firewall.vrrpPriority.WAN_VIP;
          virtualIps = builtins.map (ip: { addr = ip.ip; dev = ip.dev; }) config.hv-Firewall.vrrpIps;
          trackScripts = [ "add_default_gw" "del_default_gw" ];
        };
        LAN_VIP = {
          interface = config.hv-Firewall.heartbeatInterface;
          state = "BACKUP";
          virtualRouterId = 52;
          priority = config.hv-Firewall.vrrpPriority.LAN_VIP;
          virtualIps = builtins.map (ip: { addr = ip.ip; dev = ip.dev; }) (lib.filter (ip: ip.dev == config.hv-Firewall.lanInterface) config.hv-Firewall.vrrpIps);
        };
      };
    };

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;
    };

    assertions = [
      {
        assertion = config.hv-Firewall.vrrpPriority.WAN_VIP != 0;
        message = "vrrpPriority.WAN VIP must be set to a non zero value.";
      }
      {
        assertion = config.hv-Firewall.vrrpPriority.LAN_VIP != 0;
        message = "vrrpPriority LAN VIP must be set to a non zero value.";
      }
    ];

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
