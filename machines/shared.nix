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

  services.displayManager = lib.mkIf (config.specialisation != {}) {
    defaultSession = "none+i3";
  };

  services.xserver = lib.mkIf (config.specialisation != { }) {
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
    gnumake
    xclip
    nixfmt-rfc-style
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  specialisation = {
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
      ];

      # Enable the gnome-keyring secrets vault.
      # Will be exposed through DBus to programs willing to store secrets.
      services.gnome.gnome-keyring.enable = true;

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
