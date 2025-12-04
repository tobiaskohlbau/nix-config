{
  isNative,
  machineName,
  ...
}:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  mkIfElse = cond: a: b: [
    (lib.mkIf cond a)
    (lib.mkIf (!cond) b)
  ];
in
{
  imports = [
    ./helix-steel.nix
  ];

  # Homemanager needs this in order to work. Otherwise errors are thrown.
  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = "hx";
  };

  xdg.enable = true;

  home.packages =
    with pkgs;
    [
      jq
      yq-go
      fzf
      fd
      htop
      ripgrep
    ]
    ++ lib.optionals isLinux [
      meld
      xcwd
      unzip
      firefox
      rofi
      ghostty
      xsettingsd
    ]
    ++ lib.optionals isNative [
      brightnessctl
      pavucontrol
      discord
    ]
    ++ lib.optionals isDarwin [
      yubikey-agent
    ];

  home.file.".npmrc".text = ''
    prefix = ''${HOME}/.npm;
  '';

  services.xsettingsd = {
    enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-light";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = lib.concatStrings [
        "$directory"
        "$kubernetes"
        "$character"
      ];

      character = {
        success_symbol = "➜";
        error_symbol = "➜";
      };

      kubernetes = {
        disabled = false;
      };
    };
  };

  programs.fish = {
    enable = true;
    package = pkgs.fish;

    interactiveShellInit = ''
      # Check for active ssh agent forwarding.
      # I use this to use my yubikey-agent after sshing into dev once from host.
      if test -n $SSH_AUTH_SOCK
        set -x -U SSH_AUTH_SOCK $SSH_AUTH_SOCK
      else
        set -x -U SSH_AUTH_SOCK /opt/homebrew/var/run/yubikey-agent.sock
      end
      fish_add_path $HOME/go/bin
      jj util completion fish | source
    '';

    shellAbbrs = {
      xclip = "xclip -selection c";
      jf = "jj git fetch";
    };
    plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "63c8f8e65761295da51029c5b6c9e601571837a1";
          hash = "sha256-i9FcuQdmNlJnMWQp7myF3N0tMD/2I0CaMs/PlD8o1gw=";
        };
      }
    ];

    functions = {
      fish_user_key_bindings = {
        body = ''
          bind \e\cB f;
        '';
      };

      cdr = {
        wraps = "cd (git rev-parse --show-toplevel)";
        body = ''
          cd (git rev-parse --show-toplevel) $argv;
        '';
      };

      f = {
        body = ''
          set INITIAL_QUERY ""
          set RG_PREFIX "rg --line-number --no-heading --color=always --smart-case --no-ignore-vcs"

          FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY'" \
          fzf --delimiter=":" --nth=2.. --bind "change:reload:$RG_PREFIX {q} || true" \
              --ansi --query "$INITIAL_QUERY" \
              --no-sort --preview-window 'down:40%:+{2}' \
              --preview 'bat --style=numbers --color=always --highlight-line {2} {1}'

        '';
      };

      fh = {
        body = ''
            set INITIAL_QUERY ""
            if test -z $argv[1]
              set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case --hidden"
            else
              set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case -g '$argv[1]' --hidden"
            end
            echo $RG_PREFIX

          	FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY'" \
          	fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                --ansi --disabled --query "$INITIAL_QUERY" \
                --height=50% --layout=reverse
        '';
      };

      fxsc = {
        body = ''
          # allow fixing display resolution after vm window resizing or monitor change
          set screen_name (xrandr | grep -w connected | awk '{print $1}')
          echo $screen_name

          xrandr --output $screen_name --auto --dpi $argv[1]
          i3-msg restart
        '';
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tobias Kohlbau";
        email = "tobias@kohlbau.de";
      };
      signing = {
        key = "~/.ssh/id_ed25519.pub";
        signByDefault = false;
      };
      extraConfig = {
        color.ui = true;
        github.user = "tobiaskohlbau";
        push = {
          default = "upstream";
          autoSetupRemote = true;
        };
        init.defaultBranch = "main";
        core.editor = "hx";
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        merge.tool = "meld";
        gpg.format = "ssh";
      };
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.jujutsu = {
    enable = true;
    package = pkgs.jujutsu;

    settings = {
      user = {
        name = "Tobias Kohlbau";
        email = "tobias@kohlbau.de";
      };

      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@-)"
          "--to"
          "@-"
        ];
      };

      revset-aliases = {
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = {
        light = "gruvbox_light_hard";
        dark = "gruvbox_dark_hard";
      };
      editor = {
        true-color = true;
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
          left = [
            "mode"
            "spinner"
          ];
          center = [ "file-name" ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
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

        file-picker = {
          hidden = false;
        };
      };
      keys = {
        normal."+" = {
          i = ":toggle-option lsp.display-inlay-hints";
          h = {
            g = ":toggle-option file-picker.git-ignore";
            h = ":toggle-option file-picker.hidden";
          };
          c = ":insert-output ~/tmp/commitgenerator/commitgenerator";
          b = ":forge-blame";
          o = ":forge-open";
        };
        normal."space" = {
          F = "file_picker_in_current_buffer_directory";
        };
      };
    };

    languages = {
      language = [
        {
          name = "go";
          formatter = {
            command = "goimports";
          };
        }
      ];
    };

    ignores = [
      ".direnv/"
    ];

    steel = {
      enable = true;
      cogs = {
        forge = builtins.readFile ./cogs/forge.scm;
        notes = builtins.readFile ./cogs/notes.scm;
      };
    };
  };

  programs.go = {
    enable = true;
    package = pkgs.go;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  xdg.configFile = {
    "i3/config".text = builtins.readFile ./i3;
    "gdb/gdbinit".text = builtins.readFile ./gdbinit;
  };

  home.pointerCursor = lib.mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
