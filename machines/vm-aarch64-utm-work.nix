{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./vm-aarch64-utm.nix
    inputs.nix-config-private.nixosModules.syseleven
  ];

  networking.enableIPv6 = false;
  networking.interfaces.enp0s1.mtu = 1340;
  virtualisation.docker.extraOptions = "--mtu 1340";

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
