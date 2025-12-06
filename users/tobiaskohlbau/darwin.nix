{ inputs, pkgs, ... }:

{
  system.primaryUser = "tobias";
  ids.gids.nixbld = 350;

  nix.enable = true;

  home-manager.users.tobias = {
    xdg.configFile."ghostty/config".text = builtins.readFile ./ghostty.darwin;

    home.packages = with pkgs; [
      gnused
    ];

    programs.fish.functions = {
      nightmode = {
        body = ''
          osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
          pkill -USR1 hx
        '';
      };
      daymode = {
        body = ''
          osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
          pkill -USR1 hx
        '';
      };
    };
  };

  homebrew = {
    enable = true;
    casks = [
      "dash"
      "discord"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.tobias = {
    home = "/Users/tobias";
    shell = pkgs.fish;
  };

  launchd.user.agents.yubikey-agent = {
    path = [
      pkgs.yubikey-agent
      "/usr/bin"
    ];
    command = "yubikey-agent -l /tmp/yubikey-agent.socket";
    serviceConfig = {
      Label = "org.nixos.yubikey-agent";
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardErrorPath = "/tmp/yubikey-agent.log";
      StandardOutPath = "/tmp/yubikey-agent.log";
    };
  };

  environment.variables = {
    SSH_AUTH_SOCK = "/tmp/yubikey-agent.socket";
  };

  system.stateVersion = 5;
}
