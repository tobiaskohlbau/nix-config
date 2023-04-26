{ config, pkgs, lib, ... }: {

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dev";
  networking.interfaces.enp0s1.useDHCP = true;

  security.sudo.wheelNeedsPassword = false;
  virtualisation.docker.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = false;

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;
  services.openssh.permitRootLogin = "no";

  networking.firewall.enable = false;

  system.stateVersion = "22.11";

  environment.systemPackages = with pkgs; [
    gnumake
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
