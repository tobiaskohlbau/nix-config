name: { nixpkgs, home-manager, system, user, overlays, nix-config-private }:

nixpkgs.lib.nixosSystem rec {
  inherit system;

  modules = [
    { nixpkgs.overlays = overlays; }

    ../machines/${name}.nix
    ../users/${user}/nixos.nix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = {
        imports = [
          ../users/${user}/home-manager.nix
          "${nix-config-private}/home-manager.nix"
        ];
      };
    }
  ];
}
