{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steel-helix.url = "github:mattwparas/helix/steel-event-system";
    steel.url = "github:mattwparas/steel";

    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+https://github.com/tobiaskohlbau/nix-config-private";
    ghostty = {
      # temporary switch to fork which fixes mode 2031 support
      # url = "github:ghostty-org/ghostty";
      url = "github:tobiaskohlbau/ghostty/push-lrvtvupzsxpx";
    };
    zig.url = "github:mitchellh/zig-overlay";
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
        (final: prev: {
          steel-helix = inputs.steel-helix.packages.${prev.stdenv.hostPlatform.system}.default;
        })
        (final: prev: { steel = inputs.steel.packages.${prev.stdenv.hostPlatform.system}.default; })
        (final: prev: { ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default; })
        inputs.fonts.overlays.default
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; };
        })
        (final: prev: import ./pkgs { pkgs = nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}; })
        inputs.zig.overlays.default
      ];
    in
    {
      formatter = {
        "aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixfmt-tree;
        "aarch64-darwin" = nixpkgs.legacyPackages."aarch64-darwin".nixfmt-tree;
      };
      nixosConfigurations = {
        vm-aarch64-utm = mkMachine "vm-aarch64-utm" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
        };
        vm-aarch64-utm-work = mkMachine "vm-aarch64-utm-work" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
        };
        pc-x86_64 = mkMachine "pc-x86_64" {
          system = "x86_64-linux";
          user = "tobiaskohlbau";
          native = true;
        };
      };
      darwinConfigurations.macbook = mkMachine "macbook" {
        system = "aarch64-darwin";
        user = "tobias";
        darwin = true;
      };
    };
}
