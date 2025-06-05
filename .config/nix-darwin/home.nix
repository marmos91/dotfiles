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

    settings = {
      theme = "catppuccin-mocha";
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
        "git"
        "docker"
        "kubectl"
        "tmux"
        "vi-mode"
        "history-substring-search"
        "colored-man-pages"
        "command-not-found"
        "nvm"
        "z"
      ];
    };

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
      reload-nix =
        "darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
    };

    sessionVariables = {
      PATH =
        "$PATH:/etc/profiles/per-user/marmos91/bin:/opt/homebrew/bin:/run/current-system/sw/bin:$HOME/.local/bin";
    };

    initContent = ''
      # Initialize Oh My Posh
      if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/config.toml)"
      fi

      # Fish-like autosuggestions behavior
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

      # Better history (fish-like)
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY
      setopt APPEND_HISTORY
      setopt INC_APPEND_HISTORY

      # Auto cd (fish-like)
      setopt AUTO_CD

      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
      zstyle ':completion:*' menu select

      # History substring search keybindings (fish-like up/down arrow)
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey -M vicmd 'k' history-substring-search-up
      bindkey -M vicmd 'j' history-substring-search-down

      # FZF integration (replaces fzf-fish)
      if command -v fzf >/dev/null 2>&1; then
        # Ctrl+R for command history
        bindkey '^R' fzf-history-widget
        # Ctrl+T for file search
        bindkey '^T' fzf-file-widget
        # Alt+C for directory search
        bindkey '\ec' fzf-cd-widget
      fi
    '';
  };

  # Enable fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Enable zoxide (modern z replacement)
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
    extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
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
      "github" = { user = "marmos91"; };
      "hub" = { protocol = "ssh"; };
      "pull" = { rebase = true; };
      "fetch" = { prune = true; };
      "push" = { autoSetupRemote = true; };
      "init" = { defaultBranch = "main"; };
      "gpg" = {
        format = "ssh";
        "ssh" = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      "filter" = {
        "lfs" = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
      "alias" = {
        "ls-subtrees" =
          "!\"git log | grep git-subtree-dir | awk '{ print $2 }'";
      };
      "include" = { path = "~/.config/git/config.local"; };
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
        "darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
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
      neofetch
    '';
  };

  home.packages = with pkgs; [
    _1password-cli
    ansible
    awscli2
    bazelisk
    btop
    buildifier
    certbot
    cmake
    commitlint
    diff-so-fancy
    envsubst
    ffmpeg
    gh
    git-lfs
    go-task
    go_1_23
    hub
    jq
    k9s
    kubectl
    kubectx
    lazygit
    neofetch
    neovim
    nixfmt-classic
    nodejs
    oh-my-posh
    python310
    reattach-to-user-namespace
    ripgrep
    rustup
    stow
    tilt
    tldr
    tmuxinator
    tree
    wget
    wireguard-tools
    yt-dlp
    zstd
  ];
}
