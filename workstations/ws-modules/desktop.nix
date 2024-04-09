{ config, pkgs, ... }:

{
  # Security settings
  security.pam.services.waylock = {
    text = "auth include login";
  };

  # Enable cache for Hyprland to speed up builds
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # Hyprland configuration and package inclusion
  programs.hyprland.enable = true;

  # System package inclusion for a comprehensive desktop environment
  environment.systemPackages = with pkgs; [

    # Hyprland
    inputs.hyprland-contrib.packages.x86_64-linux.grimblast
    rofi-wayland
    wlsunset
    wl-clipboard
    hyprland
    waybar
    libsForQt5.qt5ct
    hyprland-protocols
    hyprland-per-window-layout
    xdg-desktop-portal-hyprland
    nwg-displays
    pavucontrol
    swaylock
    waylock
    swww
    swaynotificationcenter
    wlogout
    dunst
    gnome.gnome-clocks # World Clock

    # Web Browsers
    firefox
    tor

    # VPN
    mullvad-vpn

    # Development Tools
    vscode
    libreoffice-fresh
    dbeaver
    fik
    kubectl
    vim
    gdu
    glances
    meld
    gotop
    k9s
    lazydocker
    lazygit
    gnome.gnome-calculator
    gnome.cheese
    broot
    rofi
    audacity
    handbrake
    parsec-bin
    jellyfin
    vmware-horizon-client
    prismlauncher # Minecraft
    steam-tui
    protonup-qt

    # Communication Tools
    zoom-us
    signal-desktop
    nheko
    teams-for-linux
    webex
    beeper

    # Media Applications
    gimp
    inkscape
    obs-studio
    mpv
    vlc
    zathura
    feh
    libsForQt5.okular
    yt-dlp

    # Terminal Utilities
    zellij
    htop
    fzf
    alacritty
    keychain
    gnupg
    jq
    rsync
    rclone

    # Fonts
    fira-code

    # System Tools
    kalker
    iamb
    cinnamon.nemo

    # Fish Shell Extensions
    fishPlugins.tide
    fishPlugins.fzf-fish
  ];


  # X11 and desktop environment settings
  services.xserver = {
    enable = true;
    desktopManager.plasma5.enable = true;
    displayManager.sddm.enable = true;
    displayManager.defaultSession = "plasmawayland";
    layout = "us";
    xkbVariant = "";
  };

  # Greetd display manager configuration for a welcoming login interface
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "blake";
      };
    };
  };

  # Systemd service configuration for greetd
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Prevents errors from spamming on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Environment setup for greetd
  environment.etc."greetd/environments".text = ''
    Hyprland
    fish
    startplasma-wayland
  '';

  # Set environmental variables for session
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Printing, sound, and realtime audio processing services
  services.printing.enable = true;
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };


  # Gaming
  programs.java.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  };

  # Change wallpaper every 5 minutes
  systemd.timers."swww-random" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Unit = "swww-random.service";
    };
  };

  systemd.services."swww-random" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/set_random_wallpaper.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };

  # Pushes updates to second brain every 1 minutes
  systemd.timers."update-second-brain" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "update-second-brain.service";
    };
  };

  systemd.services."update-second-brain" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/update-second-brain.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };

  # Pushes updates to dotfiles every 1 minutes
  systemd.timers."update-dotfiles" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "update-dotfiles.service";
    };
  };

  systemd.services."update-dotfiles" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/update-dotfiles.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };


  #  # Update the system ever hour
  #   systemd.timers."update-system" = {
  #     wantedBy = [ "timers.target" ];
  #     timerConfig = {
  #       OnBootSec = "60min";
  #       OnUnitActiveSec = "60min";
  #       Unit = "update-system.service";
  #     };
  #   };

  #   systemd.services."update-system" = {
  #     script = ''
  #       /run/current-system/sw/bin/fish /home/blake/scripts/update-system.fish
  #     '';
  #     serviceConfig = {
  #       Type = "oneshot";
  #       User = "blake";
  #     };
  #   };


  # Change Hyprland gaps every 30 minutes to protect oled
  systemd.timers."gaps-random" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30min";
      OnUnitActiveSec = "30min";
      Unit = "gaps-random.service";
    };
  };

  systemd.services."gaps-random" = {
    script = ''
      /run/current-system/sw/bin/fish /home/blake/scripts/set_random_gaps.fish
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "blake";
    };
  };
  # Enable and configure the GPG agent
  programs.gnupg.agent = {
    enable = true;
    settings = {
      default-cache-ttl = 86400;
      max-cache-ttl = 86400;
    };
    pinentryFlavor = "gnome3"; # Choose the appropriate pinentry flavor
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };

  services = {
    # Syncthing
    # Available at http://127.0.0.1:8384
    syncthing = {
      enable = true;
      user = "blake";
      dataDir = "/home/blake/Documents/";
      configDir = "/home/blake/.config/syncthing";
      overrideDevices = true; # overrides any devices added or deleted through the WebUI
      overrideFolders = true; # overrides any folders added or deleted through the WebUI
      settings = {
        devices = {
          "Hermes" = {
            id = "THUQIF6-TGOYFXY-5H5YKV3-VHRW5GL-KIPYJZO-3FKD2W6-4LKV6AP-GJEQGQD";
          };
        };
        options = {
          urAccepted = -1;
        };
        folders = {
          "Documents" = {
            # Name of folder in Syncthing, also the folder ID
            path = "/home/blake/Documents"; # Which folder to add to Syncthing
            devices = [ "Hermes" ]; # Which devices to share the folder with
          };
          #   "Example" = {
          #     path = "/home/myusername/Example";
          #     devices = [ "device1" ];
          #     ignorePerms = false;  # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
          #   };
          # };
        };
      };
    };
  };

  # Firefox

  programs.firefox = {
    enable = true;

    policies = {
      BackgroundAppUpdate = false;
      DisableFeedbackCommands = true;
      DisableFirefoxAccounts = false;
      DisableFirefoxScreenshots = false;
      DisableFirefoxStudies = true;
      DisableForgetButton = false;
      DisableFormHistory = true;
      DisableMasterPasswordCreation = true;
      DisablePasswordReveal = false;
      DisablePocket = true;
      DisablePrivateBrowsing = false;
      DisableProfileImport = false;
      DisableProfileRefresh = false;
      DisableSafeMode = false;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      #      DisableThirdPartyModuleBlocking = true;
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://dns.nextdns.io/e59afb";
      };
      DontCheckDefaultBrowser = true;
      # EnableTrackingProtection = {
      #   Value = true;
      #   Locked = false;
      # };
      EnterprisePoliciesEnabled = true;
      ExtensionUpdate = true;
      FirefoxHome = {
        TopSites = false;
        Highlights = false;
        Pocket = false;
        Snippets = false;
        Search = true;
        Locked = false;
      };
      FirefoxSuggest = {
        History = true;
        Bookmarks = true;
        OpenTabs = true;
        Shortcuts = false;
        SearchEngines = true;
      };
      HardwareAcceleration = true;
      NetworkPrediction = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      PasswordManagerEnabled = false;
      PictureInPicture = {
        Enabled = true;
        Locked = false;
      };
      PopupBlocking = {
        Default = true;
        Locked = false;
      };
      PrintingEnabled = true;
      PromptForDownloadLocation = false;
      SanitizeOnShutdown = {
        All = false;
        Selective = {
          History = true;
          Cookies = false;
        };
      };
      SearchBar = "unified";
      SearchEngines = {
        Add = [{
          Name = "Kagi";
          URLTemplate = "https://kagi.com/search?q=%s";
        }];
        Default = "Kagi";
        PreventInstalls = true;
        Remove = [ "Bing" "Yahoo" ];
      };
      SearchSuggestEnabled = true;
      SSLVersionMin = "tls1.2";
      StartDownloadsInTempDirectory = true;
      UserMessaging = {
        WhatsNew = false;
      };
      UseSystemPrintDialog = true;
    };
    #       # Privacy about:config settings
    #       preferences = {
    #               "browser.send_pings" = false;
    #               "browser.urlbar.speculativeConnect.enabled" = false;
    #               "dom.event.clipboardevents.enabled" = true;
    #               "media.navigator.enabled" = false;
    # #              "network.cookie.cookieBehavior" = 1;
    #               "network.http.referer.XOriginPolicy" = 2;
    #               "network.http.referer.XOriginTrimmingPolicy" = 2;
    #               "beacon.enabled" = false;
    #               "browser.safebrowsing.downloads.remote.enabled" = false;
    #               "network.IDN_show_punycode" = true;
    #               "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
    #               "dom.security.https_only_mode_ever_enabled" = true;
    #               "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    #               "browser.toolbars.bookmarks.visibility" = "never";
    #               "geo.enabled" = false;
    #               "browser.bookmarks.addedImportButton" = false;
    #               "browser.bookmarks.restore_default_bookmarks" = false;
    #               "browser.download.useDownloadDir" = false;
    #               "browser.startup.homepage" = "about:blank";
    #               "browser.newtabpage.pinned" = "[]";
    #               "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    #               "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    #               "privacy.clearOnShutdown.history" = true;
    #               "privacy.donottrackheader.enabled" = true;
    #               "privacy.fingerprintingProtection" = true;

    #               # Disable telemetry
    #               "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    #               "browser.ping-centre.telemetry" = false;
    #               "browser.tabs.crashReporting.sendReport" = false;
    #               "devtools.onboarding.telemetry.logged" = false;
    #               "toolkit.telemetry.enabled" = false;
    #               "toolkit.telemetry.unified" = false;
    #               "toolkit.telemetry.server" = "";
    #               "app.shield.optoutstudies.enabled" = true;

    #               # Disable Pocket
    #               "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
    #               "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    #               "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
    #               "browser.newtabpage.activity-stream.showSponsored" = false;
    #               "extensions.pocket.enabled" = false;

    #               # Disable prefetching
    #               # "network.dns.disablePrefetch" = true;
    #               # "network.prefetch-next" = false;

    #               # Disable JS in PDFs
    #               "pdfjs.enableScripting" = false;

    #               # Harden SSL 
    #               "security.ssl.require_safe_negotiation" = true;

    #               # Extra
    #               # "identity.fxaccounts.enabled" = false;
    #               "browser.search.suggest.enabled" = true;
    #               "browser.urlbar.shortcuts.bookmarks" = true;
    #               "browser.urlbar.shortcuts.history" = true;
    #               "browser.urlbar.shortcuts.tabs" = false;
    #               "browser.urlbar.suggest.bookmark" = true;
    #               "browser.urlbar.suggest.engines" = false;
    #               "browser.urlbar.suggest.history" = true;
    #               "browser.urlbar.suggest.openpage" = false;
    #               "browser.urlbar.suggest.topsites" = false;
    #               "browser.uidensity" = 1;
    #               "media.autoplay.enabled" = false;
    #               # "toolkit.zoomManager.zoomValues" = ".8,.90,.95,1,1.1,1.2";

    #               "privacy.firstparty.isolate" = true;
    #               "network.http.sendRefererHeader" = 0;
    #           };
  };

}
