{ config, lib, pkgs, ... }:

let
  cfg = config.services.keepalived;
  wanGatewayPath = config.age.secrets."wan-gateway".path;
  publicIp1Path = config.age.secrets."public-ip-1".path;

  secretEnvFile = "/run/secrets/keepalived.env";

  scriptTemplate = name: command: pkgs.writeScript "${name}.sh" ''
    #!/bin/sh
    IP=$WAN_GATEWAY_IP
    ip route ${command} default via $IP
  '';

  addGatewayScriptPath = "/run/agenix/add-gateway.sh";
  delGatewayScriptPath = "/run/agenix/del-gateway.sh";
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
  };

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
            # Allow established and related connections
            ct state {established, related} accept;
            # Allow DNS queries from specified LAN DNS forwarders to the DNS server
            iifname "${config.hv-Firewall.lanInterface}" ip saddr { ${lib.concatStringsSep ", " config.hv-Firewall.dnsForwardingAddresses} } udp dport 53 accept;
            # Explicitly drop all incoming connections on the WAN interface
            iifname "${config.hv-Firewall.wanInterface}" drop;
          }
          chain forward {
            type filter hook forward priority 0;
            # Only allow forwarding of established or related connections
            ct state {established, related} accept;
            # Drop all other forwarded packets by default
            policy drop;
          }
          chain output {
            type filter hook output priority 0;
            # Accept all outbound packets initiated from within your network
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

    fileSystems."/run/dnscrypt-proxy" = {
      fsType = "tmpfs";
      device = "tmpfs";
      options = [
        "nosuid"
        "nodev"
        "noexec"
        "size=50M"
      ];
    };

    systemd.services.keepalived-secrets = {
      description = "Export secrets for Keepalived";
      before = [ "keepalived.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "keepalived_script";
        Group = "keepalived_script";
        ExecStart = pkgs.writeScript "export-secrets.sh" ''
          #!/bin/sh
          touch ${secretEnvFile}
          echo "WAN_GATEWAY_IP=$(cat ${wanGatewayPath})" > ${secretEnvFile}
          echo "PUBLIC_IP_1=$(cat ${publicIp1Path})" >> ${secretEnvFile}
          chmod 600 ${secretEnvFile}
        '';
      };
    };


    age.secrets."wan-gateway".owner = "keepalived_script";
    age.secrets."public-ip-1".owner = "keepalived_script";

    environment.etc."agenix/add-gateway.sh".mode = "0700";
    environment.etc."agenix/add-gateway.sh".user = "keepalived_script";
    environment.etc."agenix/del-gateway.sh".mode = "0700";
    environment.etc."agenix/del-gateway.sh".user = "keepalived_script";

    systemd.mounts = [
      {
        what = "tmpfs";
        where = "/run/secrets";
        type = "tmpfs";
        options = "nosuid,nodev,noexec,size=1M,mode=0700";
        wantedBy = [ "multi-user.target" ];
      }
    ];

    users.users.keepalived_script = {
      isSystemUser = true;
      description = "User for Keepalived scripts";
      group = "keepalived_script";
    };

    users.groups.keepalived_script = { };

    services.keepalived = {
      enable = true;
      secretFile = secretEnvFile;
      vrrpScripts = {
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
