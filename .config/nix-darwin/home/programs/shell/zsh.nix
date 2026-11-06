{ config, pkgs, lib, hostname, username, ... }:
let
  shellFunctions = import ./functions.nix { inherit pkgs hostname username; };

  # Feeds the `secrets` completion lists; the script itself lives in
  # home/packages.nix.
  secretNames = lib.concatStringsSep " " (lib.naturalSort (builtins.attrNames config.sops.secrets));
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

      # AI agents (route Claude Code through Headroom context compression)
      # The GitHub MCP plugin reads GITHUB_PERSONAL_ACCESS_TOKEN; scope it to
      # claude instead of exporting it to every process.
      claude = "GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token 2>/dev/null) headroom wrap claude --memory --code-graph";

      # tmux
      ta = "tmux attach";
      ts = "tmux new -s";
      tl = "tmux list-sessions";

      # gcal sync setup (needs the nix python that carries google-api-client)
      gcal-setup = "${pkgs.python313.withPackages (ps: [ ps.google-api-python-client ps.google-auth-oauthlib ])}/bin/python3 ~/.dotfiles/.local/bin/gcal-personal-block --setup";

      # System
      top = "btop";
      cat = "bat";
      python = "python3";
      pip = "pip3";
      cd = "z";
      neofetch = "fastfetch";

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
      # Raise file descriptor limit (macOS default is too low for many dev tools)
      ulimit -n 10240

      # compinit is run (and cached) by oh-my-zsh; do not run it again here.
      # A second `compinit` re-audits all of fpath and rewrites the dump on
      # every shell, which costs ~1s of the startup time.

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
      # Alt-, rather than Ctrl+Space: tmux's prefix is C-Space, so it never
      # reaches the pane there.
      bindkey '^[,' autosuggest-accept

      # mkcd, nix-shell-p, nix-run, flake-update, rebuild
      source ${shellFunctions}

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

      # kubectl/helm/docker completions come from carapace (terminal/carapace.nix).

      # `secrets` itself is a script in home/packages.nix — one copy for both
      # shells instead of two that drift.
      _secrets() {
        local -a commands secrets
        commands=(
          'edit:Edit encrypted secrets'
          'view:View decrypted secrets'
          'add:Add a new secret'
        )
        secrets=(${secretNames})

        case "$words[2]" in
          edit|view)
            _describe 'secret' secrets
            ;;
          *)
            _describe 'command' commands
            ;;
        esac
      }
      compdef _secrets secrets

      # List available SSH hosts from config and config.d
      ssh-hosts() {
        echo "Available SSH hosts:"
        echo ""
        grep -h "^Host " ~/.ssh/config ~/.ssh/config.d/* 2>/dev/null | grep -v "[*?]" | awk '{print $2}' | sort | column
      }
    '';
  };
}
