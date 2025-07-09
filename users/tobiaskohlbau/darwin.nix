{ inputs, pkgs, ... }:

{
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "dash"
      "discord"
      "rectangle"
      "alacritty"
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
