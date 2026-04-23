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
    helix.url = "github:mattwparas/helix?rev=cba44fdf36d1c728468da73a5373348c7d831fb7";
    steel.url = "github:mattwparas/steel?rev=605d490c07ae6937d532d5a994920b4dab3016ad";

    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nix-config-private.url = "git+https://github.com/tobiaskohlbau/nix-config-private";
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    zig.url = "github:mitchellh/zig-overlay";
    opencode.url = "github:anomalyco/opencode";
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
          helix = inputs.helix.packages.${prev.stdenv.hostPlatform.system}.default;
          fish = prev.fish.overrideAttrs (prevAttrs: {
            # Bust the cache key so fish is always built locally rather than
            # substituted from the binary cache where the signature may be stale.
            NIX_FORCE_LOCAL_REBUILD = "darwin-codesign-fix";
          });
        })
        (final: prev: { steel = inputs.steel.packages.${prev.stdenv.hostPlatform.system}.default; })
        (final: prev: { ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default; })
        inputs.fonts.overlays.default
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; };
        })
        (final: prev: import ./pkgs { pkgs = nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}; })
        inputs.zig.overlays.default
        (final: prev: { opencode = inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default; })
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
        vm-aarch64-utm-qemu = mkMachine "vm-aarch64-utm-qemu" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
        };
        vm-aarch64-fusion = mkMachine "vm-aarch64-fusion" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
        };
        vm-aarch64-utm-qemu-work = mkMachine "vm-aarch64-utm-qemu" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
          extraModules = [
            inputs.nix-config-private.nixosModules.syseleven
          ];
        };
        pc-x86_64 = mkMachine "pc-x86_64" {
          system = "x86_64-linux";
          user = "tobiaskohlbau";
          native = true;
        };
        llm = mkMachine "llm" {
          system = "aarch64-linux";
          user = "tobiaskohlbau";
        };
      };
      darwinConfigurations.macbook = mkMachine "macbook" {
        system = "aarch64-darwin";
        user = "tobias";
        darwin = true;
      };
    };
}
