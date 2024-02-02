{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix/86023cf1e6c9ab12446061e40c838335c5790979";
    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+https://github.com/tobiaskohlbau/nix-config-private";
    # fonts.url = "git+https:tobiaskohlbau/fonts-nix";
    # nix-config-private.url = "git+https:tobiaskohlbau/nix-config-private";
    zig.url = "github:mitchellh/zig-overlay";
  };


  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkVM = import ./lib/mkvm.nix;
      overlays = [
        (final: prev: { inherit (inputs.helix.packages.${prev.system}) helix; })
        inputs.fonts.overlays.default
        inputs.zig.overlays.default
        (
          final: prev: {
            unstable = import inputs.nixpkgs-unstable { system = final.system; };
          }
        )
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
      nixosConfigurations.pc-x86_64 = mkVM "pc-x86_64" {
        inherit nixpkgs home-manager overlays nix-config-private;
        system = "x86_64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.laptop-x86_64 = mkVM "laptop-x86_64" {
        inherit nixpkgs home-manager overlays nix-config-private;
        system = "x86_64-linux";
        user = "tobiaskohlbau";
      };
    };
}
