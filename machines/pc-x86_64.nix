{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware/pc-x86_64.nix
    ./shared.nix
  ];

  networking.hostName = "ampere";

  services.xserver.dpi = 140;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  time.hardwareClockInLocalTime = true;
}
