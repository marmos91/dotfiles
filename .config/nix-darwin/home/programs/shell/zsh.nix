{ config, pkgs, lib, hostname, username, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
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

      # Usability
      setopt CORRECT INTERACTIVE_COMMENTS NO_BEEP

      # Keybindings
      bindkey '^ ' autosuggest-accept  # Ctrl+Space to accept suggestion

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
        source <(command docker completion zsh 2>/dev/null || true)
        command docker "$@"
      }

      rebuild() {
        ${if isDarwin then ''
        if [[ $EUID -eq 0 ]]; then
          darwin-rebuild switch --flake ~/.config/nix-darwin#${hostname} "$@"
        else
          sudo darwin-rebuild switch --flake ~/.config/nix-darwin#${hostname} "$@"
        fi
        '' else ''
        local arch=$(uname -m)
        if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
          home-manager switch --flake ~/.config/nix-darwin#${username}-aarch64 "$@"
        else
          home-manager switch --flake ~/.config/nix-darwin#${username} "$@"
        fi
        ''}
      }
    '';
  };
}
