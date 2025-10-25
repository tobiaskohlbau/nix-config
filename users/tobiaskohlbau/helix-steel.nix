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
    scms = mkOption {
      type = types.attrs;
      default = { };
      example = [ ];
      description = '''';
    };
  };

  config = mkIf cfg.enable {
    programs.helix.package = pkgs.steel-helix.overrideAttrs (prevAttrs: {
      cargoBuildFeatures = [
        "helix-term/steel"
      ];
    });
    xdg.configFile =
      lib.mapAttrs' (
        n: v:
        lib.nameValuePair "helix/${n}.scm" {
          source =
            if lib.isString v then
              pkgs.writeText "${n}.scm" v
            else if builtins.isPath v || lib.isStorePath v then
              v
            else
              abort "Unsupported value type!";
        }
      ) cfg.scms
      // {
        "helix/helix.scm" = {
          text = ''
            (require "helix/editor.scm")
            (require "helix/misc.scm")

            (define (current-path)
              (let* ([focus (editor-focus)]
                     [focus-doc-id (editor->doc-id focus)])
                (editor-document->path focus-doc-id)))

            (provide current-path)

            ;; Implementation detail that should be cleaned up. We shouldn't really make
            ;; this accessible at the top level like this - it should more or less be a
            ;; reserved detail. These should not be top level values, and if they are
            ;; top level values, they should have a better name.
            ;;
            ;; This is simply an implementation defined behavior.
            (define (path->package path)
              (eval (string->symbol (string-append "__module-mangler" (canonicalize-path path) "__%#__"))))

            (define (module->exported path)
              (~> path path->package hash-keys->list))

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: ''
                (require "${k}.scm")
                (provide ${k})
              '') cfg.scms
            )}
          '';
        };
        "helix/init.scm".text = ''
          (require (prefix-in helix. "helix/commands.scm"))
          (require (prefix-in helix.static. "helix/static.scm"))
          (require "helix/configuration.scm")
        '';
      };
  };
}
