{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")

    ./hardware/vm-aarch64-prl.nix
    ./shared.nix
  ];

  hardware.parallels.enable = true;

  systemd.user.services = builtins.listToAttrs (
    map
      (svc: {
        name = "${svc}";
        value = {
          enable = false;
        };
      })
      [
        # "prlcp"
        "prlcc"
        "prldnd"
        "prlga"
        "prlshprof"
      ]
  );

  networking.interfaces.enp0s5.useDHCP = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
