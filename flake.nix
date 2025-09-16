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
    helix.url = "github:mattwparas/helix/steel-event-system";

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
        (final: prev: { steel-helix = inputs.helix.packages.${prev.system}.default; })
        (final: prev: { ghostty = inputs.ghostty.packages.${prev.system}.default; })
        inputs.fonts.overlays.default
        inputs.zig.overlays.default
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable { system = final.system; };
        })
        (final: prev: {
          ghostty-software = prev.ghostty.overrideAttrs (prevAttrs: {
            postInstall = (prevAttrs.postInstall or "") + ''
              wrapProgram $out/bin/ghostty --set LIBGL_ALWAYS_SOFTWARE 1
            '';
          });
        })
      ];
    in
    {
      formatter."aarch64-linux" = nixpkgs.legacyPackages."aarch64-linux".nixfmt-tree;
      nixosConfigurations.vm-aarch64-utm = mkMachine "vm-aarch64-utm" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
      };
      nixosConfigurations.vm-aarch64-utm-work = mkMachine "vm-aarch64-utm" {
        system = "aarch64-linux";
        user = "tobiaskohlbau";
        modules = [
          inputs.nix-config-private.nixosModules.syseleven
        ];
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
        modules = [
          inputs.nixos-hardware.nixosModules.microsoft-surface-common
        ];
      };
      darwinConfigurations.macbook = mkMachine "macbook" {
        system = "aarch64-darwin";
        user = "tobiaskohlbau";
        darwin = true;
      };
    };
}
