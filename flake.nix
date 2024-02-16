{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+https://github.com/tobiaskohlbau/nix-config-private";
    zig.url = "github:mitchellh/zig-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };


  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      mkVM = import ./lib/mkvm.nix {
        inherit overlays nixpkgs inputs;
      };
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
    in
    {
      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixpkgs-fmt;
      nixosConfigurations.vm-aarch64-utm = mkVM "vm-aarch64-utm" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.pc-x86_64 = mkVM "pc-x86_64" {
        system = "x86_64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.laptop-x86_64 = mkVM "laptop-x86_64" {
        system = "x86_64-linux";
        user = "tobiaskohlbau";
        surface = true;
      };
    };
}
