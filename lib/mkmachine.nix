{
  nixpkgs,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  native ? false,
  darwin ? false,
  ...
}@rest:

let
  isNative = native;
  home-manager =
    if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  libSystem = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
in
libSystem rec {
  inherit system;

  modules = [
    { nixpkgs.overlays = overlays; }

    ../machines/${name}.nix
    ../users/${user}/${if darwin then "darwin" else "nixos"}.nix
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/tobiaskohlbau/home-manager.nix {
        inherit isNative;
        machineName = name;
      };
    }
  ]
  ++ rest.modules;
}
