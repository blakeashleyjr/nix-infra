{ config, lib, pkgs, ... }:

with lib;

{
  ## Security Configuration
  ## This configuration includes a variety of security enhancements, borrowing
  ## elements from community resources and aiming to harden the system against various attack vectors.

  ## Kernel and Module Security Settings
  security = {
    protectKernelImage = true; # Enforce kernel image protection; consider evaluating the performance/security trade-off.
    lockKernelModules = true; # Lock kernel modules to prevent unauthorized modifications.
    forcePageTableIsolation = true; # Mitigate certain side-channel attacks like Meltdown.

    rtkit.enable = true; # Enable Real-Time Kit for real-time priorities.

    apparmor = {
      enable = true; # Enable AppArmor for mandatory access control.
      killUnconfinedConfinables = true; # Kill processes that cannot be confined by AppArmor.
      packages = [ pkgs.apparmor-profiles ]; # Include default AppArmor profiles.
    };
  };

  ## Sysctl Settings for Additional Kernel Hardening
  boot.kernel.sysctl = {
    # General protection settings.
    "kernel.kptr_restrict" = 2; # Hide kernel pointers, even from processes with CAP_SYSLOG.
    "kernel.printk" = "3 3 3 3"; # Limit kernel message logging to prevent information leakage.
    "kernel.sysrq" = 4; # Restrict Secure Attention Key functions to prevent unauthorized access.
    "kernel.yama.ptrace_scope" = 2; # Limit PTRACE usage to enhance process isolation.
    "net.core.bpf_jit_enable" = false; # Disable BPF JIT compiler to mitigate spray attacks.
    "kernel.ftrace_enabled" = false; # Disable ftrace to prevent debugging and tracing by attackers.

    # Network security enhancements.
    "dev.tty.ldisc_autoload" = 0; # Disable TTY line discipline autoloading.
    "net.ipv4.tcp_syncookies" = 1; # Enable SYN cookies to protect against SYN flood attacks.
    "net.ipv4.tcp_rfc1337" = 1; # Use RFC 1337 fix to protect against TIME-WAIT assassination.
    "net.ipv4.conf.all.log_martians" = true; # Log martian packets to detect misrouting or attacks.
    "net.ipv4.conf.all.rp_filter" = "1"; # Enable strict reverse path filtering.
    "net.ipv4.icmp_echo_ignore_broadcasts" = true; # Ignore ICMP broadcasts to mitigate SMURF attacks.
    "net.ipv4.conf.all.accept_redirects" = false; # Ignore ICMP redirects to prevent routing attacks.
    "net.ipv4.conf.all.secure_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false; # Apply the same settings for IPv6.

    # Congestion and throughput optimizations.
    "net.core.default_qdisc" = "fq"; # Use Fair Queueing to improve packet scheduling.
    "net.ipv4.tcp_congestion_control" = "bbr"; # Enable BBR for improved congestion control.
  };

  ## Kernel Module Blacklisting
  ## Prevent loading of modules for obsolete or insecure protocols and filesystems.
  boot.blacklistedKernelModules = [
    "ax25"
    "netrom"
    "rose" # Obsolete network protocols.
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs" # Insecure or rarely used filesystems.
  ];

  ## Sudo and User Privilege Settings
  security.sudo.execWheelOnly = true; # Restrict sudo execution to the wheel group.
  security.sudo.extraConfig = "Defaults lecture = never"; # Disable sudo lectures for a cleaner user experience.
  # Enable passwordless sudo for users in the 'wheel' group
  security.sudo.wheelNeedsPassword = false;

  ## Nix and Systemd Settings for Build and Runtime Efficiency
  nix.settings = {
    connect-timeout = 5; # Reduce connect timeout to fail quickly if substituters are unavailable.
    log-lines = mkDefault 25; # Increase log line storage for better debugging information.
    max-free = mkDefault (3000 * 1024 * 1024); # Set maximum free space to prevent disk full issues.
    min-free = mkDefault (512 * 1024 * 1024); # Set minimum free space to ensure system responsiveness.
    builders-use-substitutes = true; # Prefer using substitutes when available to reduce build times.
    allowed-users = mkDefault [ "@wheel" ]; # Restrict Nix usage to the wheel group.
  };

  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = mkDefault 250; # Prioritize important services over builds.

  ## Additional Security Measures
  boot.kernelPackages = mkDefault pkgs.linuxPackages_hardened; # Use hardened kernel for enhanced security.

  security.allowSimultaneousMultithreading = false; # Disable SMT to protect against side-channel attacks.
  security.unprivilegedUsernsClone = mkDefault config.virtualisation.containers.enable; # Allow unprivileged user namespaces if containers are enabled.
  security.virtualisation.flushL1DataCache = mkDefault "always"; # Flush L1 cache on VM entry/exit to mitigate side-channel attacks.

  boot.kernelParams = [ "slab_nomerge" "page_poison=1" "page_alloc.shuffle=1" "debugfs=off" ]; # Kernel parameters for additional hardening.

  systemd.coredump.enable = false; # Disable core dumps to prevent information leakage.

  # enable antivirus clamav and
  # keep the signatures' database updated
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

  # Note: Some settings are deliberately set with `mkDefault` or `mkOverride` to ensure they take precedence or allow user overrides.

  ## Per-App systemd hardening:

  systemd.services.systemd-rfkill = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      MemoryDenyWriteExecute = true; #
      NoNewPrivileges = true;
      LockPersonality = true; #
      RestrictRealtime = true; #
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.syslog = {
    serviceConfig = {
      PrivateNetwork = true;
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" "CAP_SYSLOG" "CAP_NET_BIND_SERVICE" ];
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      PrivateMounts = true;
      SystemCallArchitectures = "native";
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      ProtectKernelTunables = true;
      RestrictRealtime = true;
      PrivateUsers = true;
      PrivateTmp = true;
      UMask = "0077";
      RestrictNamespace = true;
      ProtectProc = "invisible";
      ProtectHome = true;
      DeviceAllow = false;
      ProtectSystem = "full";
    };
  };
  systemd.services.systemd-journald = {
    serviceConfig = {
      UMask = 0077;
      PrivateNetwork = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
    };
  };
  systemd.services.auto-cpufreq = {
    serviceConfig = {
      CapabilityBoundingSet = "";
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateNetwork = true;
      IPAddressDeny = "any";
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectHostname = false;
      MemoryDenyWriteExecute = true;
      ProtectClock = true;
      RestrictNamespaces = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectProc = true;
      ReadOnlyPaths = [ "/" ];
      InaccessiblePaths = [ "/home" "/root" "/proc" ];
      SystemCallFilter = [ "@system-service" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
  systemd.services.NetworkManager-dispatcher = {
    serviceConfig = {
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateUsers = true;
      PrivateDevices = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.display-manager = {
    serviceConfig = {
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true; # so we won't need all of this
    };
  };
  systemd.services.emergency = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # Might need adjustment for emergency access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."getty@tty1" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."getty@tty7" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET";
      RestrictNamespaces = true;
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.NetworkManager = {
    serviceConfig = {
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      SystemCallArchitectures = "native";
      MemoryDenyWriteExecute = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      ProtectKernelTunables = true;
      ProtectHome = true;
      PrivateTmp = true;
      UMask = "0077";
    };
  };
  systemd.services."nixos-rebuild-switch-to-configuration" = {
    serviceConfig = {
      ProtectHome = true;
      NoNewPrivileges = true; # Prevent gaining new privileges
    };
  };
  systemd.services."dbus" = {
    serviceConfig = {
      PrivateTmp = true;
      PrivateNetwork = true;
      ProtectSystem = "full";
      ProtectHome = true;
      SystemCallFilter = "~@clock @cpu-emulation @module @mount @obsolete @raw-io @reboot @swap";
      ProtectKernelTunables = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = [ "~CAP_SYS_TIME" "~CAP_SYS_PACCT" "~CAP_KILL" "~CAP_WAKE_ALARM" "~CAP_SYS_BOOT" "~CAP_SYS_CHROOT" "~CAP_LEASE" "~CAP_MKNOD" "~CAP_NET_ADMIN" "~CAP_SYS_ADMIN" "~CAP_SYSLOG" "~CAP_NET_BIND_SERVICE" "~CAP_NET_BROADCAST" "~CAP_AUDIT_WRITE" "~CAP_AUDIT_CONTROL" "~CAP_SYS_RAWIO" "~CAP_SYS_NICE" "~CAP_SYS_RESOURCE" "~CAP_SYS_TTY_CONFIG" "~CAP_SYS_MODULE" "~CAP_IPC_LOCK" "~CAP_LINUX_IMMUTABLE" "~CAP_BLOCK_SUSPEND" "~CAP_MAC_*" "~CAP_DAC_*" "~CAP_FOWNER" "~CAP_IPC_OWNER" "~CAP_SYS_PTRACE" "~CAP_SETUID" "~CAP_SETGID" "~CAP_SETPCAP" "~CAP_FSETID" "~CAP_SETFCAP" "~CAP_CHOWN" ];
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [ "~AF_PACKET" "~AF_NETLINK" ];
      ProtectHostname = true;
      LockPersonality = true;
      RestrictRealtime = true;
      PrivateUsers = true;
    };
  };

  systemd.services.reload-systemd-vconsole-setup = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      PrivateUsers = true;
      PrivateDevices = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.rescue = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # Might need adjustment for rescue operations
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6"; # Networking might be necessary in rescue mode
      RestrictNamespaces = true;
      SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need to be relaxed for network troubleshooting in rescue mode
    };
  };
  systemd.services."systemd-ask-password-console" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # May need adjustment for console access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # A more permissive filter
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."systemd-ask-password-wall" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # A more permissive filter
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services."user@1000" = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true; # Be cautious, as this may restrict user operations
      PrivateDevices = true;
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust based on user needs
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any";
    };
  };
  systemd.services.virtlockd = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # May need adjustment for accessing VM resources
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust as necessary
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need adjustment for network operations
    };
  };
  systemd.services.virtlogd = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true;
      PrivateDevices = true; # May need adjustment for accessing VM logs
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6";
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust based on log management needs
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need to be relaxed for network-based log collection
    };
  };
  systemd.services.virtlxcd = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true; # Necessary for container management
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true; # Be cautious, might need adjustment for container user management
      PrivateDevices = true; # Containers might require broader device access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6"; # Necessary for networked containers
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust based on container operations
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need to be relaxed for network functionality
    };
  };
  systemd.services.virtqemud = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true; # Necessary for VM management
      ProtectKernelModules = true; # May need adjustment for VM hardware emulation
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true; # Be cautious, might need adjustment for VM user management
      PrivateDevices = true; # VMs might require broader device access
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6"; # Necessary for networked VMs
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust based on VM operations
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need to be relaxed for network functionality
    };
  };
  systemd.services.virtvboxd = {
    serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true; # Required for some VM management tasks
      ProtectKernelModules = true; # May need adjustment for module handling
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateUsers = true; # Be cautious, might need adjustment for VM user management
      PrivateDevices = true; # VMs may require access to certain devices
      PrivateIPC = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = "AF_INET AF_INET6"; # Necessary for networked VMs
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ]; # Adjust based on VM operations
      SystemCallArchitectures = "native";
      UMask = "0077";
      IPAddressDeny = "any"; # May need to be relaxed for network functionality
    };
  };
}
