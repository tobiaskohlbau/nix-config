{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware/pc-x86_64.nix
    inputs.nixos-hardware.outputs.nixosModules.microsoft-surface-common
    ./shared.nix
  ];

  networking.hostName = "surfacebook";

  networking.wireless.enable = true;
  networking.wireless.environmentFile = "/root/wifi.secrets";
  networking.wireless.networks = {
    Hertz.psk = "@PSK_HERTZ@";
  };

  services.xserver.xkb.options = "caps:swapescape";
}
