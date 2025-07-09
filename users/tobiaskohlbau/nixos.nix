{ pkgs, ... }:

{
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
