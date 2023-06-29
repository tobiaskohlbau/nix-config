{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/3876cc613ac3983078964ffb5a0c01d00028139e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
    fonts.url = "git+ssh://git@github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+ssh://git@github.com/tobiaskohlbau/nix-config-private";
  };


  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkVM = import ./lib/mkvm.nix;
      overlays = [
        (final: prev: { inherit (inputs.helix.packages.${prev.system}) helix; })
        inputs.fonts.overlays.default
      ];
      nix-config-private = inputs.nix-config-private;
    in
    {
      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixpkgs-fmt;
      nixosConfigurations.vm-aarch64-utm = mkVM "vm-aarch64-utm" {
        inherit nixpkgs home-manager overlays nix-config-private;
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
    };
}
