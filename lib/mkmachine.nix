{ nixpkgs, overlays, inputs}:


name: { system, user, native ? false }:

let
  isNative = native;
  isSurface = name == "surfacebook";
  home-manager = inputs.home-manager.nixosModules;
  nix-config-private = inputs.nix-config-private;
in nixpkgs.lib.nixosSystem rec {
  inherit system;

  modules = [
    { nixpkgs.overlays = overlays; }

    (if isSurface then inputs.nixos-hardware.nixosModules.microsoft-surface-common else {})

    ../machines/${name}.nix
    ../users/${user}/nixos.nix
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../users/${user}/home-manager.nix {
        inherit isNative;
        privateNixConfig = nix-config-private;
      };
    }
  ];
}
