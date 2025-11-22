{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    steel-helix.url = "github:mattwparas/helix/steel-event-system";
    steel.url = "github:mattwparas/steel";

    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+https://github.com/tobiaskohlbau/nix-config-private";
    zig.url = "github:mitchellh/zig-overlay";
    ghostty = {
      url = "git+https://github.com/ghostty-org/ghostty";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      ...
    }@inputs:
    let
      mkMachine = import ./lib/mkmachine.nix {
        inherit overlays nixpkgs inputs;
      };
      overlays = [
        (final: prev: { steel-helix = inputs.steel-helix.packages.${prev.system}.default; })
        (final: prev: { steel = inputs.steel.packages.${prev.system}.default; })
        (final: prev: { ghostty = inputs.ghostty.packages.${prev.system}.default; })
        inputs.fonts.overlays.default
        inputs.zig.overlays.default
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable { system = final.system; };
        })
      ];
    in
    {
      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixfmt-tree;
      formatter."aarch64-darwin" = nixpkgs.legacyPackages."aarch64-darwin".nixfmt-tree;
      nixosConfigurations.vm-aarch64-utm = mkMachine "vm-aarch64-utm" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.vm-aarch64-utm-work = mkMachine "vm-aarch64-utm-work" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.vm-aarch64-utm-qemu = mkMachine "vm-aarch64-utm-qemu" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.vm-aarch64-prl = mkMachine "vm-aarch64-prl" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.pc-x86_64 = mkMachine "pc-x86_64" {
        system = "x86_64-linux";
        user = "tobiaskohlbau";
        native = true;
      };
      nixosConfigurations.surfacebook = mkMachine "surfacebook" {
        system = "x86_64-linux";
        user = "tobiaskohlbau";
        native = true;
      };
      darwinConfigurations.macbook = mkMachine "macbook" {
        system = "aarch64-darwin";
        user = "tobias";
        darwin = true;
      };
    };
}
