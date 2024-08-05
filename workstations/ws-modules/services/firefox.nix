{ config, pkgs, ... }:
{
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
        Remove = ["Bing" "Yahoo"];
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
