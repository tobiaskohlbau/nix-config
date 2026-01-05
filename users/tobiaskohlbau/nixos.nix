{ pkgs, ... }:

{
  home-manager.users.tobiaskohlbau = {
    xdg.configFile."ghostty/config".text = builtins.readFile ./ghostty.linux;

    programs.fish.functions = {
      nightmode = {
        body = ''
          dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        '';
      };
      daymode = {
        body = ''
          dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
        '';
      };
    };

    programs.ghostty = {
      enable = true;
      systemd.enable = true;
      package = pkgs.ghostty;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      configPackages = with pkgs; [ xdg-desktop-portal-gtk ];
    };
  };

  programs.fish.enable = true;
  users.users.tobiaskohlbau = {
    shell = pkgs.fish;
    isNormalUser = true;
    home = "/home/tobiaskohlbau";
    extraGroups = [
      "docker"
      "wheel"
    ];
    hashedPassword = "$6$evJlDB/8f73rPHnl$KSAf1O53Z2msdH8mdPYcDEuLPsOBTELS5yAkGOVAb9S/SsOZ.U5KmsYxaAGi03AB4CuDbUybWY6jUFzb4aWpn.";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHkuTe7ZxN/0s2l8Hq0iCsMB5r6VS2l/KOXsh0BSna1SrtvqwNEMrA/Pmh8grGyZ3bUQM7pPw+XLa7fhh3gpgeo="
    ];
  };
}
