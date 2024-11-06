{ config, pkgs, lib, ... }: {
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # installed version do not change
  system.stateVersion = "23.11";

  services.libinput = {
    enable = true;
    mouse = {
      naturalScrolling = true;
    };
  };

  services.displayManager.defaultSession = "none+i3";

  services.xserver = {
    enable = true;

    xkb = {
      layout = "us";
    };

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
    };

    windowManager = {
      i3.enable = true;
    };

    displayManager = {
      lightdm.enable = true;
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
    helix
    gnumake
    xclip
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
