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
}:

let
  isNative = native;
  isSurface = name == "surfacebook";
  home-manager =
    if darwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  nix-config-private = inputs.nix-config-private;
  libSystem = if darwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
in
libSystem rec {
  inherit system;

  modules = [
    { nixpkgs.overlays = overlays; }

    (if isSurface then inputs.nixos-hardware.nixosModules.microsoft-surface-common else { })

    ../machines/${name}.nix
    ../users/${user}/${if darwin then "darwin" else "nixos"}.nix
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${if darwin then "tobias" else user} = import ../users/${user}/home-manager.nix {
        inherit isNative;
        privateNixConfig = nix-config-private;
      };
    }
  ];
}
