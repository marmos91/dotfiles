{ config, pkgs, hostname, ... }:
{
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
        "colored-man-pages"
        "extract"
        "git"
        "safe-paste"
        "vi-mode"
      ];
    };

    shellAliases = {
      # Development
      bazel = "bazelisk";
      g = "hub";
      gg = "lazygit";

      # tmux
      ta = "tmux attach";
      ts = "tmux new -s";
      tl = "tmux list-sessions";

      # System
      top = "btop";
      cat = "bat";
      python = "python3";
      pip = "pip3";
      cd = "z";

      # Neovim
      vim = "nvim";
      vi = "nvim";
      v = "nvim";

      # Nix shortcuts
      nix-gc = "nix-collect-garbage -d && nix-store --optimize";
      nix-search = "nix search nixpkgs";
      nix-shell = "nix-shell --command zsh";

      # Directory shortcuts
      dotfiles = "cd ~/.dotfiles";
      config = "cd ~/.config";
    };

    initContent = ''
      # Performance: Only rebuild compinit once per day
      autoload -Uz compinit
      if [[ -n $HOME/.zcompdump(#qNmh+24) ]]; then
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

      bazel() {
        unfunction bazel
        # Load completion only when first used
        source <(command bazel completion zsh 2>/dev/null || true)
        bazel "$@"
      }

      # Lazy load kubectl (biggest offender)
      kubectl() {
        unfunction kubectl
        source <(command kubectl completion zsh)
        kubectl "$@"
      }

      # Lazy load helm
      helm() {
        unfunction helm
        source <(command helm completion zsh)
        helm "$@"
      }

      # Lazy load docker completion
      docker() {
        unfunction docker
        # Docker completion is provided by the plugin, load it only when needed
        docker "$@"
      }

      rebuild() {
        if [[ $EUID -eq 0 ]]; then
          # Already running as root
          darwin-rebuild switch --flake ~/.config/nix-darwin#${hostname} "$@"
        else
          # Not root, use sudo
          sudo darwin-rebuild switch --flake ~/.config/nix-darwin#${hostname} "$@"
        fi
      }
    '';
  };
}
