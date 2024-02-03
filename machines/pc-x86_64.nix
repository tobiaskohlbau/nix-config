{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware/pc-x86_64.nix
    ./shared.nix
  ];

  networking.hostName = "ampere";
}
