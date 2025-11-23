{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.helix.steel;
in
{

  options.programs.helix.steel = {
    enable = lib.mkEnableOption "helix steel support";
    cogs = mkOption {
      type = types.attrs;
      default = { };
      example = [ ];
      description = ''cogs to use'';
    };

    extraInit = mkOption {
      type = types.lines;
      default = "";
      example = "(require module.scm)";
      description = ''additional configuration appended to default init.scm'';
    };

    extraHelix = mkOption {
      type = types.lines;
      default = "";
      example = "(require module.scm)";
      description = ''additional configuration appended to default helix.scm'';
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables.STEEL_HOME = "${config.xdg.dataHome}/steel";
    programs.helix = {
      package = pkgs.steel-helix.overrideAttrs (prevAttrs: {
        cargoBuildFeatures = [
          "helix-term/steel"
        ];
      });

      extraPackages = with pkgs; [
        steel
        schemat
      ];

      languages = {
        language-server.steel = {
          command = "steel-language-server";
          args = [ ];
        };
        language = [
          {
            name = "scheme";
            formatter = {
              command = "schemat";
            };
            language-servers = [
              { name = "steel"; }
            ];
          }
        ];
      };
    };

    xdg.configFile = {
      "helix/helix.scm" = {
        text = ''
          (require "helix/editor.scm")
          (require (prefix-in helix. "helix/commands.scm"))
          (require (prefix-in helix.static. "helix/static.scm"))
        ''
        + cfg.extraHelix;
      };
      "helix/init.scm".text = ''
        (require (prefix-in helix. "helix/commands.scm"))
        (require (prefix-in helix.static. "helix/static.scm"))
        (require (only-in "helix/ext.scm" evalp eval-buffer))

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: ''
            (require "${k}.scm")
          '') cfg.cogs
        )}
      ''
      + cfg.extraInit;
    };

    xdg.dataFile = lib.mapAttrs' (
      n: v:
      lib.nameValuePair "steel/cogs/${n}.scm" {
        source = if lib.isString v then pkgs.writeText "${n}.scm" v else abort "Unsupported value type!";
      }
    ) cfg.cogs;
  };
}
