{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager?ref=6142193635ecdafb9a231bd7d1880b9b7b210d19";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
    fonts.url = "git+ssh://git@github.com/tobiaskohlbau/fonts-nix";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkVM = import ./lib/mkvm.nix;
      overlays = [
        (final: prev: { inherit (inputs.helix.packages.${prev.system}) helix; })
        inputs.fonts.overlays.default
      ];
    in
    {
      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixpkgs-fmt;
      nixosConfigurations.vm-aarch64-utm = mkVM "vm-aarch64-utm" {
        inherit nixpkgs home-manager overlays;
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
    };
}
