{
  description = "NixOS systems and tools by tobiaskohlbau";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:mattwparas/helix?rev=4d86612df48447088ef4190bf503fd54a7562aa9";
    steel.url = "github:mattwparas/steel?rev=b67efd5c262962226424148bb87abefaf4109c5a";

    fonts.url = "git+https://github.com/tobiaskohlbau/fonts-nix";
    nixpkgs-helm-unittests.url = "github:jonstacks/nixpkgs/helm-unittest-fix";
    nix-config-private = {
     url = "git+https://github.com/tobiaskohlbau/nix-config-private";
     inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    zig.url = "github:mitchellh/zig-overlay";
    opencode.url = "github:anomalyco/opencode";
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
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
        inputs.llm-agents.overlays.default
        (final: prev: {
          llama-cpp = prev.llama-cpp.overrideAttrs (
            finalAttrs: prevAttrs: {
              version = "9500";
              src = prev.fetchFromGitHub {
                owner = "ggml-org";
                repo = "llama.cpp";
                tag = "b${finalAttrs.version}";
                hash = "sha256-F0if7ydy5VN5hZ4lCSZbKXEcChr8HxbSPiYrQZ4/OE0=";
                leaveDotGit = true;
                postFetch = ''
                  git -C "$out" rev-parse --short HEAD > $out/COMMIT
                  find "$out" -name .git -print0 | xargs -0 rm -rf
                '';
              };
              npmDepsHash = "sha256-1iM0LGeI9e+gZEHk46lkBe51DxIhiimfAm9o3Z3m9Ik=";
            }
          );
        })
        (final: prev: {
          kubernetes-helmPlugins = prev.kubernetes-helmPlugins // {
            helm-unittest = inputs.nixpkgs-helm-unittests.legacyPackages.${prev.stdenv.hostPlatform.system}.kubernetes-helmPlugins.helm-unittest;
          };
        })
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
        vm-aarch64-utm-work = mkMachine "vm-aarch64-utm" {
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
