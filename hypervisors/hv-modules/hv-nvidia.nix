{ config, pkgs, imports, ... }:
{

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  environment.systemPackages = with pkgs; [
    nvidia-docker
  ];


  # Add the Nvidia kernel parameter
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ vaapiVdpau nvidia-vaapi-driver ];
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Load Nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  virtualisation.docker = {
    enableNvidia = true;
  };

}
