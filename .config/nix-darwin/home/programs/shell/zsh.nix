{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
      extended = true;
    };

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
      # Development
      bazel = "bazelisk";
      g = "hub";
      gg = "lazygit";

      # System
      top = "btop";
      cat = "bat";
      vim = "nvim";
      python = "python3";
      pip = "pip3";

      # Nix shortcuts
      rebuild = "darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
      nix-gc = "nix-collect-garbage -d && nix-store --optimize";
      nix-search = "nix search nixpkgs";

      # Directory shortcuts
      dotfiles = "cd ~/.dotfiles";
      config = "cd ~/.config";
    };

    initExtra = ''
      # Performance: Only initialize compinit if needed
      autoload -Uz compinit
      if [[ $HOME/.zcompdump(#qNmh+24) ]]; then
        compinit
      else
        compinit -C
      fi

      # Better completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '[%d]'

      # Directory navigation
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

      # History settings
      setopt HIST_VERIFY HIST_REDUCE_BLANKS HIST_IGNORE_ALL_DUPS

      # Custom functions
      extract() {
        if [ -f $1 ]; then
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
            *)           echo "'$1' cannot be extracted" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Development helpers
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # Nix helpers
      nix-shell-p() { nix-shell -p "$@"; }
      nix-run() { nix run nixpkgs#"$1" -- "''${@:2}"; }

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

      # Lazy load kubectl completion for performance
      kubectl() {
        if ! type __start_kubectl >/dev/null 2>&1; then
          source <(command kubectl completion zsh)
        fi
        command kubectl "$@"
      }
    '';
  };
}
