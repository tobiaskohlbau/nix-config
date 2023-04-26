{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkVM = import ./lib/mkvm.nix;
      overlays = [
        (final: prev: { helixpkgs = inputs.helix.packages.${prev.system}; })
        (final: prev: { cue = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.cue; })
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
