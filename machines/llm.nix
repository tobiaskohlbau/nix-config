{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];

  virtualisation.qemu.networkingOptions = lib.mkForce [
    "-device e1000,netdev=net0"
    "-netdev user,id=net0,hostfwd=tcp:127.0.0.1:2022-:22,\${QEMU_NET_OPTS:+,$QEMU_NET_OPTS}"
  ];

  networking.hostName = "llm";
  networking.enableIPv6 = lib.mkDefault false;

    nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      abort-on-warn = true
    '';
  };

  networking.nameservers = [ "9.9.9.9" ];

  time.timeZone = "Europe/Berlin";

  security.sudo.wheelNeedsPassword = false;
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = false;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "yes";
	users.users.root.initialPassword = "root";

  networking.firewall.enable = lib.mkDefault false;

  system.stateVersion = "25.11";

  environment.systemPackages = with pkgs; [
    helix
    opencode
    go
    git
    jujutsu
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  
}
