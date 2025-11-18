{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./shared.nix
  ];

  networking.hostName = "dev";
  networking.enableIPv6 = lib.mkDefault true;

  services.spice-vdagentd.enable = true;

  systemd.user.services.spice-agent = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
    };
    unitConfig = {
      ConditionVirtualization = "vm";
      Description = "Spice guest session agent";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
  };

  services.xserver.dpi = 220;
}
