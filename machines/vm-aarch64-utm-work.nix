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

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
}
