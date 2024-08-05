{ config, pkgs, ... }:
{
services = {
  # Syncthing
  # Available at http://127.0.0.1:8384
  syncthing = {
    enable = true;
    user = "blake";
    dataDir = "/home/blake/Documents/sync/";
    configDir = "/home/blake/.config/syncthing";
    overrideDevices = true;     # overrides any devices added or deleted through the WebUI
    overrideFolders = true;     # overrides any folders added or deleted through the WebUI
    settings = {
      # devices = {
      #   "Hermes" = { 
      #     id = "THUQIF6-TGOYFXY-5H5YKV3-VHRW5GL-KIPYJZO-3FKD2W6-4LKV6AP-GJEQGQD"; 
      #     };
      #   };
      options = {
        urAccepted = -1;
        };
      # folders = {
      #   "Documents" = {         # Name of folder in Syncthing, also the folder ID
      #     path = "/home/blake/Documents";    # Which folder to add to Syncthing
      #     devices = [ "Hermes" ];      # Which devices to share the folder with
      #   };
      #   "Example" = {
      #     path = "/home/myusername/Example";
      #     devices = [ "device1" ];
      #     ignorePerms = false;  # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
      #   };
      # };
      };
    };
  };
}