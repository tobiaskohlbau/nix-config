{ inputs, pkgs, ... }:

{
  homebrew = {
    enable = true;
    brews = [
      "yubikey-agent"
    ];
    casks  = [
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
}
