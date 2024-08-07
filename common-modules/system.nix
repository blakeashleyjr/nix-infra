{ pkgs, lib, inputs, ... }:
{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System update configuration
  system.autoUpgrade.enable = false;
  system.autoUpgrade.allowReboot = false;
  
  # Allow unfree
  nixpkgs.config.allowUnfree = true;
  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    # System management and orchestration
    # ansible # Automation tool for software provisioning, configuration management, and application deployment
    kubectl # Kubernetes command-line tool

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
    # go # The Go programming language
    # python3 # Python programming language, version 3

    # System and performance monitoring
    gdu # Disk usage analyzer with console interface written in Go
    glances # A cross-platform system monitoring tool
    htop # An interactive process viewer
    iotop # Monitor IO usage information live
    ncdu # NCurses Disk Usage, a disk usage analyzer with an ncurses interface

    # Disk and file management
    # gparted # Disk partitioning tool
    # rclone # Command-line program to manage files on cloud storage
    rsync # Fast incremental file transfer

    # Containers and virtualization
    docker # Platform for developing, shipping, and running applications in containers
    runc # CLI tool for spawning and running containers according to the OCI specification

    # JSON processing
    jq # Lightweight and flexible command-line JSON processor

    # Performance testing
    # stress-ng # Stress test tool with more updated features than the original stress

    # Version control systems
    git # Distributed version control system

    # Shell environments
    fish # Friendly Interactive SHell, a smart and user-friendly command line shell
    # python311Packages.pexpect # Pure Python Expect-like module
    # expect # A tool for automating interactive applications
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

}
