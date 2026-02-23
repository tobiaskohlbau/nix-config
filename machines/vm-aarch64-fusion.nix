{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware/vm-aarch64-fusion.nix
    ./shared.nix
  ];

  networking.hostName = "dev";
  networking.enableIPv6 = lib.mkDefault true;

  virtualisation.vmware.guest.enable = true;

  hardware.graphics.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    mesa
    vulkan-loader
  ];

  services.xserver.dpi = 220;
}
