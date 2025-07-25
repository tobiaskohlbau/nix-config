{
  isNative,
  machineName,
  privateNixConfig,
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
  jdtls = pkgs.writeShellScriptBin "jdtls" ''
    jdt-language-server -data $HOME/.cache/jdt.ls/data$(pwd)
  '';
  bazel = pkgs.writeShellScriptBin "bazel" (builtins.readFile ./bazel.bash);
  ibazel = pkgs.writeShellScriptBin "ibazel" (builtins.readFile ./bazel.bash);
  mkIfElse = cond: a: b: [
    (lib.mkIf cond a)
    (lib.mkIf (!cond) b)
  ];
in
{
  imports = [
    "${privateNixConfig}/home-manager.nix"
  ];

  # Homemanager needs this in order to work. Otherwise errors are thrown.
  home.stateVersion = "25.05";

  xdg.enable = true;

  home.packages =
    with pkgs;
    [
      jq
      yq
      fzf
      fd
      htop
      ripgrep
    ]
    ++ lib.optionals isLinux [
      kubectl
      kubelogin
      jdtls
      bazel
      ibazel
      gotools
      gopls
      nodejs
      pnpm
      nodePackages.svelte-language-server
      nodePackages.vscode-langservers-extracted
      glab
      kubelogin
      azure-cli
      meld
      unstable.jetbrains.idea-community
      unstable.bun
      unstable.google-java-format
      temurin-bin-21
      efm-langserver
      nodePackages.typescript-language-server
      bazel-buildtools
      k3d
      zigpkgs.master
      _1password-cli
      xcwd
      unzip
      firefox
      rofi
    ]
    ++ lib.optionals isNative [
      brightnessctl
      pavucontrol
      discord
    ]
    ++ lib.optionals isDarwin [
      yubikey-agent
    ]
    # For parallels enable ghostty with software rendering as opengl setup is broken.
    ++ mkIfElse (lib.strings.hasInfix "prl" "${machineName}") ghostty-software ghostty;

  home.sessionVariables.STEEL_HOME = "${config.xdg.dataHome}/steel";
  home.sessionVariables.STEEL_LSP_HOME = "${config.xdg.dataHome}/steel/steel-language-server";
  home.sessionVariables.HELIX_STEEL_CONFIG = "${config.xdg.configHome}/helix";

  home.file.".npmrc".text = ''
    prefix = ''${HOME}/.npm;
  '';

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-light";
    };
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Check for active ssh agent forwarding.
      # I use this to use my yubikey-agent after sshing into dev once from host.
      if test -n $SSH_AUTH_SOCK
        set -x -U SSH_AUTH_SOCK $SSH_AUTH_SOCK
      else
        set -x -U SSH_AUTH_SOCK /opt/homebrew/var/run/yubikey-agent.sock
      end
      fish_add_path $HOME/go/bin
    '';

    shellAbbrs = {
      k = "kubectl";
      xclip = "xclip -selection c";
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
      opunlock = {
        body = ''
          eval $(op signin);
        '';
      };
      kubectl = {
        body = ''
            if test "$argv[1]" = "switch";
              if test -n "$argv[2]";
                set -g kns_namespace "$argv[2]"
                return 0	
              else
                set -e kns_namespace
                return 0
              end
            end

          	if test -n "$kns_namespace";
          		command kubectl -n $kns_namespace $argv
          	else
          		command kubectl $argv
          	end
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
    userName = "Tobias Kohlbau";
    userEmail = "tobias@kohlbau.de";
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
    delta = {
      enable = true;
      options = {
        syntax-theme = "gruvbox-light";
        side-by-side = true;
        line-numbers = true;
        navigate = true;
      };
    };
    aliases = {
      cleanbr = "! git branch -d `git branch --merged | grep -v '^*\\|main'`";
      cleanpr = "! gh pr list -s merged --json headRefName -q '.[].headRefName' | xargs git branch -D";
      bsc = "! git stash && git checkout -b \"$(git rev-parse --abbrev-ref HEAD)\"-\"$(git rev-parse HEAD)\" && git fetch && git rebase -i origin/main && git push origin -u && git checkout @{-1} && git stash pop";
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -sg terminal-overrides ",*:RGB"

      set -g base-index 1
      set -g pane-base-index 1

      set -g renumber-windows on

      set -s escape-time 50

      set -g history-limit 10000

      is_hx="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?(hx)$'"
      bind-key -n 'C-h' if-shell "$is_hx" 'send-keys Space w h' 'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_hx" 'send-keys Space w j' 'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_hx" 'send-keys Space w k' 'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_hx" 'send-keys Space w l' 'select-pane -R'

      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      bind Up resize-pane -U 5
      bind Down resize-pane -D 5
      bind Left resize-pane -L 5
      bind Right resize-pane -R 5

      # Style status bar
      set -g status-style fg=white,bg=black
      set -g window-status-current-style fg=green,bg=black
      set -g pane-active-border-style fg=green,bg=black
      set -g window-status-format " #I:#W#F "
      set -g window-status-current-format " #I:#W#F "
      set -g window-status-current-style bg=green,fg=black
      set -g window-status-activity-style bg=black,fg=yellow
      set -g window-status-separator ""
      set -g status-justify centre

      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind -n C-s \
        split-window -l 10 'session=$(tmux list-sessions -F "#{session_name}" | fzf --query="$1" --select-1 --exit-0) && tmux switch-client -t "$session"' \;

      # Use vim keybindings in copy mode
      setw -g mode-keys vi
      # Setup 'v' to begin selection as in Vim
      bind-key -T copy-mode-vi v send -X begin-selection
      # Setup 'y' to copy selection as in Vim
      # Use reattach-to-user-namespace with pbcopy on OS X
      # Use xclip on Linux
      set -g set-clipboard off
      set -s copy-command 'pbcopy 2> /dev/null'
      bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel

      # Mousemode
      # Toggle mouse on with ^B m
      bind m \
        set -g mouse on \;\
        display 'Mouse Mode: ON'

      # Toggle mouse off with ^B M
      bind M \
        set -g mouse off \;\
        display 'Mouse Mode: OFF'

      # Move current window to the left with Ctrl-Shift-Left
      bind-key -n C-S-Left swap-window -t -1
      # Move current window to the right with Ctrl-Shift-Right
      bind-key -n C-S-Right swap-window -t +1
    '';
  };

  home.sessionVariables = {
    EDITOR = "hx";
  };

  programs.helix = {
    enable = true;
    extraPackages = [ pkgs.racket ];
    settings = {
      theme = "gruvbox_light";
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

      };
      keys = {
        normal."+" = {
          i = ":toggle-option lsp.display-inlay-hints";
          h = {
            g = ":toggle-option file-picker.git-ignore";
            h = ":toggle-option file-picker.hidden";
          };
          c = ":insert-output ~/tmp/commitgenerator/commitgenerator";
        };
        normal."space" = {
          F = "file_picker_in_current_buffer_directory";
        };
      };
    };

    languages = {
      language-server.eslint = {
        command = "vscode-eslint-language-server";
        args = [ "--stdio" ];
        config = {
          codeActionsOnSave = {
            mode = "all";
            "source.fixAll.eslint" = true;
          };
          format = {
            enable = true;
          };
          nodePath = "";
          quiet = false;
          rulesCustomizations = [ ];
          run = "onType";
          validate = "on";
          experimental = { };
          problems = {
            shortenToSingleLine = false;
          };
          codeAction = {
            disableRuleComment = {
              enable = true;
              location = "separateLine";
            };
            showDocumentation = {
              enable = false;
            };
          };
        };
      };
      language-server.efm = {
        command = "efm-langserver";
        config = {
          documentFormatting = true;
          languages = {
            typescript = [
              {
                formatCommand = "npx prettier --stdin-filepath \${INPUT}";
                formatStdin = true;
              }
            ];
          };
        };
      };
      language-server.typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        config = {
          hostInfo = "helix";
        };
      };
      language-server.jdtls = {
        config = {
          extendedClientCapabilities = {
            classFileContentsSupport = true;
          };
          settings.java = {
            import = {
              generatesMetadataFilesAtProjectRoot = true;
            };
            # "import".gradle = {
            #   enabled = true;
            #   user.home = "/home/tobiaskohlbau/.gradle";
            #   offline.enabled = true;
            # };
            eclipse.downloadSources = true;
            configuration.updateBuildConfiguration = "automatic";
          };
        };
      };

      language-server.steel = {
        command = "steel-language-server";
        args = [ ];
        environment = {
          STEEL_LSP_HOME = "/home/tobiaskohlbau/.config/steel-lsp/";
        };
      };

      language = [
        {
          name = "java";
          formatter = {
            command = "google-java-format";
            args = [ "-" ];
          };
          auto-format = true;
        }
        {
          name = "go";
          formatter = {
            command = "goimports";
          };
        }
        {
          name = "typescript";
          auto-format = true;
          language-servers = [
            {
              name = "efm";
              only-features = [
                "format"
                "diagnostics"
              ];
            }
            {
              name = "typescript-language-server";
              except-features = [
                "format"
                "diagnostics"
              ];
            }
            { name = "eslint"; }
          ];
        }
        {
          name = "starlark";
          formatter = {
            command = "buildifier";
            args = [ "-" ];
          };
          auto-format = true;
        }
        {
          name = "scheme";
          formatter = {
            command = "raco";
            args = [
              "fmt"
              "-i"
            ];
          };
          language-servers = [
            { name = "steel"; }
          ];
        }
      ];
      # {
      #   name = "kotlin";
      #   formatter = {
      #     command = "ktlint";
      #     args = ["-F"];
      #   };
      #   indent = { tab-width = 2; unit = "\t"; };
      # }];
    };
  };

  programs.go = {
    enable = true;
    package = pkgs.unstable.go_1_23;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.alacritty = {
    enable = true;
  };

  xdg.configFile =
    {
      "alacritty/alacritty.toml".text = builtins.readFile ./alacritty.toml;
      "i3/config".text = builtins.readFile ./i3;
      "gdb/gdbinit".text = builtins.readFile ./gdbinit;
      "helix/helix.scm".text = builtins.readFile ./helix.scm;
      "helix/init.scm".text = builtins.readFile ./init.scm;
    }
    // (
      if isLinux then
        {
          "ghostty/config".text = builtins.readFile ./ghostty.linux;
        }
      else
        { }
    );

  home.pointerCursor = lib.mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
