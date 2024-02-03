{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware/pc-x86_64.nix
    ./shared.nix
  ];

  networking.hostName = "surfacebook";

  networking.wireless.enable = true;
  networking.wireless.environmentFile = "/root/wifi.secrets";
  networking.wireless.networks = {
    Hertz.psk = "@PSK_HERTZ@";
  };
}
