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
      # Override GNOME's SSH agent with 1Password (GNOME sets SSH_AUTH_SOCK at session start)
      ${lib.optionalString (!isDarwin) ''
      if [ -S "$HOME/.1password/agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
      fi
      ''}
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

      secrets() {
        local secrets_dir="$XDG_CONFIG_HOME/nix-darwin/home/secrets"
        case "$1" in
          edit)
            if [[ -n "$2" ]]; then
              if ! command -v yq &> /dev/null; then
                echo "Note: yq is required for editing specific secrets"
                echo "Opening full secrets file instead..."
                sops "$secrets_dir/secrets.yaml"
                return
              fi
              local temp_file=$(mktemp)
              trap "rm -f '$temp_file'" RETURN
              if ! sops -d --extract "[\"$2\"]" "$secrets_dir/secrets.yaml" > "$temp_file" 2>/dev/null; then
                echo "Secret '$2' not found"
                return 1
              fi
              ''${EDITOR:-nvim} "$temp_file"
              # Decrypt, update, re-encrypt
              local dec_file=$(mktemp)
              sops -d "$secrets_dir/secrets.yaml" > "$dec_file"
              yq -i ".[\"$2\"] = load_str(\"$temp_file\")" "$dec_file"
              sops -e -i "$dec_file"
              mv "$dec_file" "$secrets_dir/secrets.yaml"
              echo "Secret '$2' updated"
            else
              sops "$secrets_dir/secrets.yaml"
            fi
            ;;
          view)
            if [[ -n "$2" ]]; then
              sops -d --extract "[\"$2\"]" "$secrets_dir/secrets.yaml"
            else
              sops -d "$secrets_dir/secrets.yaml"
            fi
            ;;
          add)
            if [[ -n "$2" ]]; then
              local name="$2"
              local target_path="$3"
              if [[ -z "$target_path" ]]; then
                echo "Usage: secrets add <name> <path>"
                echo "Example: secrets add github_token \"\\\$HOME/.config/gh/token\""
                return 1
              fi
              echo "Adding secret: $name -> $target_path"
              echo ""
              echo "Step 1: Add this to default.nix in the secrets section:"
              echo ""
              echo "      $name = {"
              echo "        path = \"$target_path\";"
              echo "        mode = \"0600\";"
              echo "      };"
              echo ""
              read "?Press Enter to open default.nix..."
              ''${EDITOR:-nvim} "$secrets_dir/default.nix"
              echo ""
              echo "Step 2: Add the secret value to secrets.yaml"
              read "?Press Enter to edit secrets.yaml..."
              sops "$secrets_dir/secrets.yaml"
              echo ""
              echo "Done! Run 'rebuild' to apply changes."
            else
              echo "Adding a new secret requires two steps:"
              echo "1. Edit default.nix to define the secret path"
              echo "2. Edit secrets.yaml to add the encrypted value"
              echo ""
              read "?Press Enter to open default.nix..."
              ''${EDITOR:-nvim} "$secrets_dir/default.nix"
              echo ""
              read "?Press Enter to edit secrets.yaml..."
              sops "$secrets_dir/secrets.yaml"
              echo ""
              echo "Done! Run 'rebuild' to apply changes."
            fi
            ;;
          *)
            echo "Usage: secrets <command> [args]"
            echo ""
            echo "Commands:"
            echo "  edit [name]       Edit secrets (all or specific)"
            echo "  view [name]       View decrypted secrets (all or specific)"
            echo "  add [name path]   Add a new secret"
            echo ""
            echo "Available secrets: kubeconfig, aws_credentials, aws_config, rclone_config"
            ;;
        esac
      }

      _secrets() {
        local -a commands secrets
        commands=(
          'edit:Edit encrypted secrets'
          'view:View decrypted secrets'
          'add:Add a new secret'
        )
        secrets=(kubeconfig aws_credentials aws_config rclone_config)

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
