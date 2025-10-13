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

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
