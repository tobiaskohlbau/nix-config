{ config, lib, pkgs, ... }:

{
  # Homemanager needs this in order to work. Otherwise errors are thrown.
  home.stateVersion = "22.11";

  home.packages = [
    pkgs.jq
    pkgs.fzf
    pkgs.htop
    pkgs.cue
  ];

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "fzf";
          rev = "24f4739fc1dffafcc0da3ccfbbd14d9c7d31827a";
          sha256 = "0kz057nr07ybh0y06ww3p424rgk8pi84pnch9jzb040qqn9a8823";
        };
      }
    ];
  };

  programs.git = {
    enable = true;
    userName = "Tobias Kohlbau";
    userEmail = "tobias@kohlbau.de";
    extraConfig = {
      color.ui = true;
      github.user = "tobiaskohlbau";
      push.default = "tracking";
      init.defaultBranch = "main";
      core.editor = "hx";
    };
  };

  programs.helix = {
    enable = true;
    package = pkgs.helixpkgs.helix;
    settings = {
      theme = "gruvbox_light_hard";
      editor = {
        whitespace = {
          render = "all";
        };
        auto-save = true;
        bufferline = "multiple";
        line-number = "relative";
        mouse = false;
        rulers = [ 120 ];

        lsp = {
          display-inlay-hints = true;
        };

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        statusline = {
          left = [ "mode" "spinner" ];
          center = [ "file-name" ];
          right = [ "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
          separator = "|";
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };

        indent-guides = {
          render = true;
          character = "|";
          skip-levels = 1;
        };

      };
      keys = {
        normal."+" = {
          i = ":toggle-option lsp.display-inlay-hints";
        };
      };
    };
  };
}
