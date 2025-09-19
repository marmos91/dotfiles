{ config, pkgs, lib, inputs, ... }: {
  home.username = "marmos91";
  home.homeDirectory = "/Users/marmos91";

  home.sessionPath = [
    "/run/current-system/sw/bin"
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batpipe
      batgrep
      batwatch
    ];
  };

  programs.ghostty = {
    enable = true;
    package = null; # Use the Cask version for now

    enableZshIntegration = true;

    settings = {
      theme = "Catppuccin Mocha";
      font-family = "MesloLGS Nerd Font Mono";
      font-size = 13;
      macos-option-as-alt = true;
      background-opacity = 0.96;
      background-blur-radius = 40;
      confirm-close-surface = false;
      mouse-hide-while-typing = true;
      macos-titlebar-style = "tabs";
    };
  };

  programs.btop = { enable = true; };

  programs.eza = {
    enable = true;
    icons = "auto";
    enableZshIntegration = true;
    git = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "bazel"
        "colored-man-pages"
        "docker"
        "extract"
        "gh"
        "git"
        "gitignore"
        "helm"
        "kubectl"
        "rust"
        "safe-paste"
        "tmux"
        "vi-mode"
        "zoxide"
      ];
    };

    shellAliases = {
      bazel = "bazelisk";
      g = "hub";
      gg = "lazygit";
      top = "btop";
      python = "python3";
      cat = "bat";
      vim = "nvim";
      reload-nix =
        "darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
    };

    sessionVariables = {
      PATH =
        "$PATH:/etc/profiles/per-user/marmos91/bin:/opt/homebrew/bin:/run/current-system/sw/bin:$HOME/.local/bin";

      # Ensure powerline symbols work
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";

      # Development environment variables
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";

      # Bat theme
      BAT_THEME = "Catppuccin-mocha";
    };

    initContent = ''
      # Optimize completion system
      autoload -Uz compinit
      if [[ ! -f ~/.zcompdump || ~/.zcompdump -ot ~/.zshrc ]]; then
        compinit
      else
        compinit -C
      fi

      # Auto cd (fish-like)
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT

      # Case insensitive completion with smart matching
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zsh/cache
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '[%d]'

      # Terminal title
      case $TERM in
        xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty|kitty*|ghostty*)
          precmd() {
            print -Pn "\e]0;%n@%m: %~\a"
          }
          preexec() {
            print -Pn "\e]0;%n@%m: %~ ($1)\a"
          }
          ;;
      esac

      # PERFORMANCE: Lazy load kubectl completion
      kubectl() {
        if ! type __start_kubectl >/dev/null 2>&1; then
          source <(command kubectl completion zsh)
        fi
        command kubectl "$@"
      }

      # Extract function for various archive types
      function extract() {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--border" ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    clock24 = true;
    terminal = "tmux-256color";
    prefix = "C-Space";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    historyLimit = 10000;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_text "#W"
          set -g @catppuccin_window_current_text "#W"
          set -g status-right-length 100
          set -g status-left-length 100
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
          set -agF status-right "#{E:@catppuccin_status_battery}"
        '';
      }
      {
        plugin = weather;
        extraConfig = ''
          set-option -g @tmux-weather-interval 1
        '';
      }
      battery
      cpu
      sensible
      yank
      resurrect
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      open
    ];
    extraConfig = ''
      # Explicitly set zsh as the default shell/command for new panes/windows
      set -g default-shell "${pkgs.zsh}/bin/zsh"
      set -g default-command "${pkgs.zsh}/bin/zsh"

      # Enable focus events (better vim/neovim integration)
      set -g focus-events on

      # Reduce escape-time (better vim/neovim experience)
      set-option -sg escape-time 10

      # Better terminal settings
      set-option -sa terminal-features ',xterm-256color:RGB'

      # Move tmux UI to the bottom
      set -g status-position bottom 

      # Reload tmux prefix
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf 

      # Clipboard
      set -g set-clipboard external

      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D 
      bind k select-pane -U
      bind l select-pane -R

      # Vim style resize panes
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5

      # Synchonize panes
      bind-key g set-window-option synchronize-panes\; display-message "synchronize-panes is now #{?pane_synchronized,on,off}"

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Keep same CWD when splitting
      unbind '"'
      unbind %

      bind c new-window -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"

      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Allow the title bar to adapt to whatever host you connect to
      set -g set-titles on
      set -g set-titles-string "#T"
    '';
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        identityAgent =
          "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

        forwardAgent = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        compression = false;
        addKeysToAgent = "no";
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "marmos91";

    signing = {
      signByDefault = true;
      key =
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1Z1G84m2eZAGLJnXNiItcqUvaL36gG2/bam73es6wDhDpdQwhb1+1kBCf3Yqq98is7zACuzKgFhrLkKPWs+1TSTCOXrL0he6MNHUdpiYhZewKNMg4A8+RkpBgJpekQr0ulhhnH7aWKZ1x+qIBc/uPOumEG0SnJM7mzoZ1KO+M2Djk64ofXOeODgCyXut/8wdpRVXjv9fttdvyQOoTFPgLqzsBCnlRR1lo3mo+AffLjwnRdH2UThW4cDiQnPCfLUAopFobC8P8plNnBdrjl3GOaCcGbbgphiJVJ9Gfb6gPMvMkQjnGlCfhvxfvCya6D0oZGA/oMZMU4+qePaSJKeyYatIdHSWtD8cn3USLIIRe0NBzsgpsluxuqLN/wYWkLGZ8jWVsPBUYWl+0V2jNmJNrk0AZwgHuhpegBU+rpCR4+LYvdB43qSHvT1e2Bjz83M5Sqbf94SpfaV0UjiUSR4HhVdmeftIrIRJLc59MIRGfQvaiII5ozCJu4nNTJa/YklM=";
    };

    extraConfig = {
      github.user = "marmos91";
      hub.protocol = "ssh";
      pull.rebase = true;
      fetch.prune = true;
      push.autoSetupRemote = true;
      init.defaultBranch = "main";

      gpg.format = "ssh";
      "gpg \"ssh\"".program =
        "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      alias.ls-subtrees =
        "!\"git log | grep git-subtree-dir | awk '{ print $2 }'";
      include.path = "~/.config/git/config.local";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    DOTFILES_DIR = "$HOME/.dotfiles";
    OBSIDIAN_VAULTS_DIR = "$HOME/vaults";
    GPG_TTY = "$(tty)";
    GITHUB_USERNAME = "marmos91";
    BACKUP_VOLUME = "/Volumes/BackupMarco";
    PNPM_HOME = "$HOME/Library/pnpm";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = ''
        [](#9A348E)$os$username[](bg:#DA627D fg:#9A348E)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#86BBD8)$golang$nodejs$rust[](fg:#06969A bg:#33658A)[ ](fg:#33658A)$fill$kubernetes$package$mem_usage$cmd_duration$hostname$time$battery$line_break$character
      '';

      # Disable the blank line at the start
      add_newline = false;

      continuation_prompt = "▶▶ ";

      fill = { symbol = "."; };

      # Username module
      username = {
        show_always = true;
        style_user = "bg:#9A348E fg:#ffffff";
        style_root = "bg:#9A348E fg:#ffffff";
        format = "[ $user ]($style)";
        disabled = false;
      };

      # Directory module with custom substitutions
      directory = {
        style = "bg:#DA627D fg:#ffffff";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = "󰉍 ";
          "Music" = " ";
          "Pictures" = " ";
          "Projects" = "󰲋 ";
        };
      };

      # Git branch
      git_branch = {
        symbol = "";
        style = "bg:#FCA17D fg:#000000";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#FCA17D fg:#000000";
        format = "[$all_status$ahead_behind ]($style)";
        conflicted = "⚡";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        up_to_date = "✓";
        untracked = "?\${count}";
        stashed = "📦\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };

      # Programming languages
      golang = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      # Python (added for your setup)
      python = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
        pyenv_version_name = true;
        python_binary = [ "python3" "python" ];
      };

      kubernetes = {
        symbol = "☸ ";
        style = "fg:#ffffff";
        format = "[ $symbol$context( \\($namespace\\)) ]($style)";
        disabled = false;
      };

      hostname = {
        ssh_only = false;
        style = "fg:#ffffff";
        format = "[ 💻 $hostname ]($style)";
        disabled = false;
      };

      time = {
        disabled = false;
        time_format = "%H:%M:%S";
        style = "fg:#ffffff";
        format = "[  $time ]($style)";
      };

      package = {
        format = "[ 📦 $version ]($style)";
        style = "fg:#ffffff";
        disabled = false;
      };

      memory_usage = {
        disabled = false;
        threshold = 70;
        format = "[ 🐏 $ram ]($style)";
        style = "bg:#f36943 fg:#ffffff";
      };

      # Command duration
      cmd_duration = {
        min_time = 2000; # Show duration for commands taking longer than 2s
        format = "[ ⏱️ $duration ]($style)";
        style = "yellow bold";
      };

      # Battery (right-aligned)
      battery = {
        format = "[ $symbol$percentage ]($style)";
        display = [
          {
            threshold = 20;
            style = "bold fg:#f36943";
          }
          {
            threshold = 50;
            style = "bold fg:#FFCD58";
          }
          {
            threshold = 100;
            style = "bold fg:#33DD2D";
          }
        ];
        full_symbol = "";
        charging_symbol = "⚡";
        discharging_symbol = "";
      };

      # Line break
      line_break = { disabled = false; };

      # Character prompt (new line)
      character = {
        success_symbol = "[⚡](bold yellow) [>](bold red)";
        error_symbol = "[⚡](bold yellow) [>](bold red)";
        vimcmd_symbol = "[⚡](bold yellow) [>](bold red)";
        format = "$symbol ";
      };
    };
  };

  programs.k9s = {
    enable = true;
    settings = { k9s = { ui = { skin = "catppuccin_mocha"; }; }; };
    skins = {
      catppuccin_mocha = {
        k9s = {
          body = {
            fgColor = "#cdd6f4";
            bgColor = "#1e1e2e";
            logoColor = "#cba6f7";
          };
          prompt = {
            fgColor = "#cdd6f4";
            bgColor = "#181825";
            suggestColor = "#89b4fa";
          };
          help = {
            fgColor = "#cdd6f4";
            bgColor = "#1e1e2e";
            sectionColor = "#a6e3a1";
            keyColor = "#89b4fa";
            numKeyColor = "#eba0ac";
          };
          frame = {
            title = {
              fgColor = "#94e2d5";
              bgColor = "#1e1e2e";
              highlightColor = "#f5c2e7";
              counterColor = "#f9e2af";
              filterColor = "#a6e3a1";
            };
            border = {
              fgColor = "#cba6f7";
              focusColor = "#b4befe";
            };
            menu = {
              fgColor = "#cdd6f4";
              keyColor = "#89b4fa";
              numKeyColor = "#eba0ac";
            };
            crumbs = {
              fgColor = "#1e1e2e";
              bgColor = "#eba0ac";
              activeColor = "#f2cdcd";
            };
            status = {
              newColor = "#89b4fa";
              modifyColor = "#b4befe";
              addColor = "#a6e3a1";
              pendingColor = "#fab387";
              errorColor = "#f38ba8";
              highlightColor = "#89dceb";
              killColor = "#cba6f7";
              completedColor = "#6c7086";
            };
            info = {
              fgColor = "#fab387";
              sectionColor = "#cdd6f4";
            };
            views = {
              table = {
                fgColor = "#cdd6f4";
                bgColor = "#1e1e2e";
                cursorFgColor = "#313244";
                cursorBgColor = "#45475a";
                markColor = "#f5e0dc";

                header = {
                  fgColor = "#f9e2af";
                  bgColor = "#1e1e2e";
                  sorterColor = "#89dceb";
                };
              };
              xray = {
                fgColor = "#cdd6f4";
                bgColor = "#1e1e2e";
                cursorColor = "#45475a";
                cursorTextColor = "#1e1e2e";
                graphicColor = "#f5c2e7";
              };
              charts = {
                bgColor = "#1e1e2e";
                chartBgColor = "#1e1e2e";
                dialBgColor = "#1e1e2e";
                defaultDialColors = [ "#a6e3a1" "#f38ba8" ];
                defaultChartColors = [ "#a6e3a1" "#f38ba8" ];
                resourceColors = {
                  cpu = [ "#cba6f7" "#89b4fa" ];
                  mem = [ "#f9e2af" "#fab387" ];
                };
              };
              yaml = {
                keyColor = "#89b4fa";
                valueColor = "#cdd6f4";
                colonColor = "#a6adc8";
              };
              logs = {
                fgColor = "#cdd6f4";
                bgColor = "#1e1e2e";
                indicator = {
                  fgColor = "#b4befe";
                  bgColor = "#1e1e2e";
                  toggleOnColor = "#a6e3a1";
                  toggleOffColor = "#a6adc8";
                };
              };

            };
            dialog = {
              fgColor = "#f9e2af";
              bgColor = "#9399b2";
              buttonFgColor = "#1e1e2e";
              buttonBgColor = "#7f849c";
              buttonFocusFgColor = "#1e1e2e";
              buttonFocusBgColor = "#f5c2e7";
              labelFgColor = "#f5e0dc";
              fieldFgColor = "#cdd6f4";
            };
          };
        };
      };
    };
  };

  programs.fish = {
    enable = false;
    plugins = with pkgs.fishPlugins; [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        };
      }
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "a34b0c2809f665e854d6813dd4b052c1b32a32b4";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
      {
        name = "fzf-fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
      {
        name = "tmux-fish";
        src = pkgs.fetchFromGitHub {
          owner = "budimanjojo";
          repo = "tmux.fish";
          rev = "e27bb956e1a39c041a151f3a2a6bb3861e265e7a";
          sha256 = "sha256-oREvB4jfmk1EH9yry7u0GkmJty0vCUxFtLgZxFMSWf4=";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          owner = "franciscolourenco";
          repo = "done";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
      {
        name = "nvm";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "nvm.fish";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];

    shellAliases = {
      bazel = "bazelisk";
      g = "hub";
      gg = "lazygit";
      top = "btop";
      python = "python3";
      cat = "bat";
      ta = "tmux attach";
      ts = "tmux new -s";
      vim = "nvim";
      obsidian = "open -a Obsidian";
      reload-nix =
        "sudo darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
    };
    shellInit = ''
      fish_add_path /etc/profiles/per-user/marmos91/bin/
      fish_add_path /opt/homebrew/bin
      fish_add_path /run/current-system/sw/bin
      fish_add_path $HOME/.local/bin
    '';
    interactiveShellInit = ''
      set -U fish_greeting ""
      # source ~/.config/op/plugins.sh
    '';
  };

  home.packages = with pkgs; [
    _1password-cli
    age
    ansible
    awscli2
    bazelisk
    btop
    buildifier
    certbot
    claude-code
    cmake
    commitlint
    diff-so-fancy
    envsubst
    fd
    ffmpeg
    gh
    git-lfs
    go-task
    go_1_23
    hub
    jq
    kubectl
    kubectx
    lazygit
    luarocks
    markdownlint-cli
    neovim
    nixfmt-classic
    nodejs
    python313
    reattach-to-user-namespace
    ripgrep
    rustup
    sd
    sshpass
    stow
    tilt
    tldr
    tmuxinator
    tree
    watch
    wget
    wireguard-tools
    yq
    yt-dlp
    zstd
  ];
}
