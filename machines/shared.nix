{ config, pkgs, lib, ... }: {
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dev";
  networking.interfaces.enp0s1.useDHCP = true;
  networking.nameservers = [ "9.9.9.9" ];

  time.timeZone = "Europe/Berlin";

  security.sudo.wheelNeedsPassword = false;
  virtualisation.docker.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = false;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  networking.firewall.enable = false;

  system.stateVersion = "23.11";

  services.xserver = {
    enable = true;
    layout = "us";
    dpi = 220;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
    };

    displayManager = {
      defaultSession = "none+i3";
      lightdm.enable = true;
    };

    windowManager = {
      i3.enable = true;
    };

    libinput = {
      enable = true;
      mouse = {
        naturalScrolling = true;
      };
    };
  };

  fonts = {
    fontconfig = {
      antialias = true;
      subpixel = {
        rgba = "none";
        lcdfilter = "none";
      };
    };
    fontDir.enable = true;
    packages = [
      pkgs.fira-code
      pkgs.fontpkgs.berkeley-mono
    ];
  };

  environment.systemPackages = with pkgs; [
    gnumake
    xclip
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
