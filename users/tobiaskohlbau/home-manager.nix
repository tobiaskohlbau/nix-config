{ config, lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
in
{
  # Homemanager needs this in order to work. Otherwise errors are thrown.
  home.stateVersion = "22.11";

  xdg.enable = true;

  home.packages = [
    pkgs.jq
    pkgs.fzf
    pkgs.htop
    pkgs.kubectl
    pkgs.kubelogin
    pkgs.ripgrep
    pkgs.xcwd
  ] ++ (lib.optionals isLinux [
    pkgs.firefox
    pkgs.rofi
  ]);

  xdg.configFile."i3/config".text = builtins.readFile ./i3;

  home.file.".npmrc".text = ''
    prefix = ''${HOME}/.npm;
  '';

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # Check for active ssh agent forwarding.
      # I use this to use my yubikey-agent after sshing into dev once from host.
      if test -n $SSH_AUTH_SOCK
        set -x -U SSH_AUTH_SOCK $SSH_AUTH_SOCK
      end
    '';

    shellAbbrs = {
      k = "kubectl";
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

    functions =
      {
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
            if test -z $argv[1]
              set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case --no-ignore-vcs"
            else
              set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case -g '$argv[1]' --no-ignore-vcs"
            end
            echo $RG_PREFIX

          	FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY'" \
          	fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                --ansi --disabled --query "$INITIAL_QUERY" \
                --height=50% --layout=reverse
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
    };
  };

  programs.git = {
    enable = true;
    userName = "Tobias Kohlbau";
    userEmail = "tobias@kohlbau.de";
    extraConfig = {
      color.ui = true;
      github.user = "tobiaskohlbau";
      push = {
        default = "upstream";
        autoSetupRemote = true;
      };
      init.defaultBranch = "main";
      core.editor = "hx";
    };
    includes = [
      {
        condition = "gitdir:~/src/github.com/myopenfactory/**/*.git";
        contents = {
          user = {
            email = "t.kohlbau@myopenfactory.com";
          };
        };
      }
    ];
  };

  programs.gh = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      #set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color*:Tc"

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

      bind r source-file ~/.tmux.conf

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

  programs.helix = {
    enable = true;
    settings = {
      theme = "gruvbox_light";
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

    languages = [{
      name = "java";
      language-server = {
        command = "jdt-language-server";
      };
      formatter = {
        command = "google-java-format";
        args = ["-"];
      };
      auto-format = true;
    }];
  };

  programs.go = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };
}
