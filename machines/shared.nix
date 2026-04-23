{
  config,
  pkgs,
  lib,
  ...
}:
{
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      abort-on-warn = true
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

  networking.firewall.enable = lib.mkDefault false;

  # installed version do not change
  system.stateVersion = "23.11";

  services.libinput = {
    enable = true;
    mouse = {
      naturalScrolling = true;
    };
  };

  services.displayManager.defaultSession = lib.mkDefault "none+i3";

  services.xserver = lib.mkDefault {
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

  services.gnome.gnome-keyring.enable = true;

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
    nixfmt-rfc-style
  ];

  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    configPackages = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  specialisation = {
    latestKernel.configuration = {
      boot.kernelPackages = pkgs.linuxPackages_latest;
    };

    wayland.configuration = {
      services.xserver = {
        enable = false;
      };

      environment.systemPackages = with pkgs; [
        grim # screenshot functionality
        slurp # screenshot functionality
        wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
        mako # notification system developed by swaywm maintainer
        lemurs
        foot
        waybar
      ];

      # Enable the gnome-keyring secrets vault.
      # Will be exposed through DBus to programs willing to store secrets.
      services.gnome.gnome-keyring.enable = true;

      services.dbus.enable = true;

      # enable Sway window manager
      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
      };

      services.displayManager.ly.enable = true;
      services.xserver.displayManager.lightdm.enable = false;

      services.displayManager = {
        defaultSession = "sway";
      };

    };
  };
}
