{ pkgs, lib, ... }:
{
  # Version specification
  system.stateVersion = "23.11"; # Don't change

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable passwordless sudo for users in the 'wheel' group
  security.sudo.wheelNeedsPassword = false;

  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # System management and orchestration
    ansible # Automation tool for software provisioning, configuration management, and application deployment

    # Text editors and file viewers
    nano # Easy to use text editor
    mc # Midnight Commander - a text-based file manager

    # Terminal multiplexers
    screen # Full-screen window manager that multiplexes a physical terminal
    tmux # Terminal multiplexer, allows multiple terminal sessions to be accessed simultaneously in a single window
    zellij # A newer terminal multiplexer aiming to be user-friendly and customizable

    # Network tools
    curl # Tool to transfer data from or to a server
    iperf3 # Network bandwidth measurement tool
    nmap # Network exploration tool and security / port scanner
    traceroute # Tracks the route packets take to a network host
    wget # Utility for non-interactive download of files from the web

    # Programming languages and runtime
    go # The Go programming language
    python3 # Python programming language, version 3

    # System and performance monitoring
    gdu # Disk usage analyzer with console interface written in Go
    glances # A cross-platform system monitoring tool
    htop # An interactive process viewer
    iotop # Monitor IO usage information live
    ncdu # NCurses Disk Usage, a disk usage analyzer with an ncurses interface

    # Disk and file management
    gparted # Disk partitioning tool
    rclone # Command-line program to manage files on cloud storage
    rsync # Fast incremental file transfer

    # Containers and virtualization
    docker # Platform for developing, shipping, and running applications in containers
    runc # CLI tool for spawning and running containers according to the OCI specification

    # JSON processing
    jq # Lightweight and flexible command-line JSON processor

    # Performance testing
    stress-ng # Stress test tool with more updated features than the original stress

    # Version control systems
    git # Distributed version control system

    # Shell environments
    fish # Friendly Interactive SHell, a smart and user-friendly command line shell
    python311Packages.pexpect # Pure Python Expect-like module
    expect # A tool for automating interactive applications
  ];


  services = {
    fail2ban = {
      enable = true;
      ignoreIP = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
      bantime = "24h";
      bantime-increment = {
        enable = true;
        formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
        maxtime = "1680h";
        overalljails = true;
      };
    };

    chrony = {
      enable = true;
      enableNTS = true;
      servers = [
        "time.cloudflare.com"
        "oregon.time.system76.com"
        "ohio.time.system76.com"
        "time.0xt.ca"
      ];
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        Port = 22;
        UseDns = false;
        PermitEmptyPasswords = false;
        ChallengeResponseAuthentication = false;
        GSSAPIAuthentication = false;
        X11Forwarding = false;
      };
    };
  };



  ## Security:
  ## Borrowed from here https://github.com/sioodmy/dotfiles/blob/main/system/core/schizo.nix by https://github.com/sioodmy

  security = {
    protectKernelImage = false;
    lockKernelModules = false;
    forcePageTableIsolation = true;

    rtkit.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
      packages = [ pkgs.apparmor-profiles ];
    };

  };

  boot.kernel.sysctl = {
    # Hide kernel pointers from processes without the CAP_SYSLOG capability.
    "kernel.kptr_restrict" = 1;
    "kernel.printk" = "3 3 3 3";
    # Restrict loading TTY line disciplines to the CAP_SYS_MODULE capability.
    "dev.tty.ldisc_autoload" = 0;
    # Make it so a user can only use the secure attention key which is required to access root securely.
    "kernel.sysrq" = 4;
    # Protect against SYN flooding.
    "net.ipv4.tcp_syncookies" = 1;
    # Protect against time-wait assasination.
    "net.ipv4.tcp_rfc1337" = 1;

    # Enable strict reverse path filtering (that is, do not attempt to route
    # packets that "obviously" do not belong to the iface's network; dropped
    # packets are logged as martians).
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.all.rp_filter" = "1";
    "net.ipv4.conf.default.log_martians" = true;
    "net.ipv4.conf.default.rp_filter" = "1";

    # Protect against SMURF attacks and clock fingerprinting via ICMP timestamping.
    "net.ipv4.icmp_echo_ignore_all" = "1";

    # Ignore incoming ICMP redirects (note: default is needed to ensure that the
    # setting is applied to interfaces added after the sysctls are set)
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.all.secure_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv4.conf.default.secure_redirects" = false;
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;

    # Ignore outgoing ICMP redirects (this is ipv4 only)
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;

    # Restrict abritrary use of ptrace to the CAP_SYS_PTRACE capability.
    "kernel.yama.ptrace_scope" = 2;
    "net.core.bpf_jit_enable" = false;
    "kernel.ftrace_enabled" = false;
  };


  # Security
  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"
    # Old or rare or insufficiently audited filesystems
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
    "vivid"
    "gfs2"
    "ksmbd"
    # "nfsv4"
    # "nfsv3"
    "cifs"
    # "nfs"
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "squashfs"
    "udf"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
  ];

  ## Much of the below is borrowed from https://github.com/nix-community/srvos/blob/main/nixos/common/nix.nix

  # use TCP BBR has significantly increased throughput and reduced latency for connections
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };


  # Only allow members of the wheel group to execute sudo by setting the executable’s permissions accordingly. This prevents users that are not members of wheel from exploiting vulnerabilities in sudo such as CVE-2021-3156.
  security.sudo.execWheelOnly = true;
  # Don't lecture the user. Less mutable state.
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  # No mutable users by default
  # users.mutableUsers = false;

  ## General

  # Fallback quickly if substituters are not available.
  nix.settings.connect-timeout = 5;

  # The default at 10 is rarely enough.
  nix.settings.log-lines = lib.mkDefault 25;

  # Avoid disk full issues
  nix.settings.max-free = lib.mkDefault (3000 * 1024 * 1024);
  nix.settings.min-free = lib.mkDefault (512 * 1024 * 1024);

  # Make builds to be more likely killed than important services.
  # 100 is the default for user slices and 500 is systemd-coredumpd@
  # We rather want a build to be killed than our precious user sessions as builds can be easily restarted.
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;

  # Avoid copying unnecessary stuff over SSH
  nix.settings.builders-use-substitutes = true;

}
