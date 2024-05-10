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

  services.logrotate.checkConfig = false; # Disable logrotate configuration checks to prevent log rotation issues and build errors.

  ## Sysctl Settings for Additional Kernel Hardening
  boot = {
    kernelParams = [ "security=apparmor" "slab_nomerge" "page_poison=1" "page_alloc.shuffle=1" "debugfs=off" ];

    kernelPackages = mkDefault pkgs.linuxPackages_hardened; # Use hardened kernel for enhanced security.

    kernel.sysctl = {
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
    blacklistedKernelModules = [
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

  };

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

  security.allowSimultaneousMultithreading = false; # Disable SMT to protect against side-channel attacks.
  security.unprivilegedUsernsClone = mkDefault config.virtualisation.containers.enable; # Allow unprivileged user namespaces if containers are enabled.
  security.virtualisation.flushL1DataCache = mkDefault "always"; # Flush L1 cache on VM entry/exit to mitigate side-channel attacks.

  systemd.coredump.enable = false; # Disable core dumps to prevent information leakage.

  # enable antivirus clamav and
  # keep the signatures' database updated
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

  # Note: Some settings are deliberately set with `mkDefault` or `mkOverride` to ensure they take precedence or allow user overrides.

  ## Per-App systemd hardening:

  # systemd.services.systemd-rfkill = {
  #   serviceConfig = {
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #     ProtectKernelTunables = true;
  #     ProtectKernelModules = true;
  #     ProtectControlGroups = true;
  #     ProtectClock = true;
  #     ProtectProc = "invisible";
  #     ProcSubset = "pid";
  #     PrivateTmp = true;
  #     MemoryDenyWriteExecute = true; #
  #     NoNewPrivileges = true;
  #     LockPersonality = true; #
  #     RestrictRealtime = true; #
  #     SystemCallFilter = [ "write" "read" "openat" "close" "brk" "fstat" "lseek" "mmap" "mprotect" "munmap" "rt_sigaction" "rt_sigprocmask" "ioctl" "nanosleep" "select" "access" "execve" "getuid" "arch_prctl" "set_tid_address" "set_robust_list" "prlimit64" "pread64" "getrandom" ];
  #     SystemCallArchitectures = "native";
  #     UMask = "0077";
  #     IPAddressDeny = "any";
  #   };
  # };

}
