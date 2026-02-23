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

  services.xserver = {
    dpi = 254;
  };

  environment.variables = {
    GDK_SCALE = "2";          # GTK3 integer scaling
    GDK_DPI_SCALE = "0.5";    # Compensate for doubled text
    QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # Qt auto-detect
  };
}
