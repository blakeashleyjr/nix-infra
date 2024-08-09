{ config, pkgs, imports, ... }:
{ 
  # Set at host level
  # hardware.nvidia = {
  #   package = config.boot.kernelPackages.nvidiaPackages.beta;
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  #   open = false;
  #   nvidiaSettings = true;
  #   forceFullCompositionPipeline = true;
  # };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ vaapiVdpau nvidia-vaapi-driver ];
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Load Nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable Nvidia for Docker
  virtualisation.docker.enableNvidia = true;

	boot = {
		extraModulePackages = [ config.boot.kernelPackages.nvidia_x11_beta ];
		initrd.kernelModules = [ "nvidia" ];
		kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "quiet" "nvidia_drm.modeset=1" "nvidia_drm.fbdev=1" ]
	};

}
