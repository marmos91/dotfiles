{ config, pkgs, hostname, username, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home.packages = with pkgs; [
    shfmt
    ast-grep
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;

    historySize = 50000;
    historyFileSize = 50000;
    historyFile = "${config.xdg.dataHome}/bash/history";
    historyControl = [ "ignoredups" "ignorespace" "erasedups" ];

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

      # Neovim
      vim = "nvim";
      vi = "nvim";
      v = "nvim";

      # Nix shortcuts
      nix-gc = "nix-collect-garbage -d && nix-store --optimize";
      nix-search = "nix search nixpkgs";

      # Directory shortcuts
      dotfiles = "cd ~/.dotfiles";
      config = "cd ~/.config";
    };

    initExtra = ''
      # Development helpers
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # Nix helpers
      nix-shell-p() { nix-shell -p "$@"; }
      nix-run() { nix run nixpkgs#"$1" -- "''${@:2}"; }

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
              read -p "Press Enter to open default.nix..."
              ''${EDITOR:-nvim} "$secrets_dir/default.nix"
              echo ""
              echo "Step 2: Add the secret value to secrets.yaml"
              read -p "Press Enter to edit secrets.yaml..."
              sops "$secrets_dir/secrets.yaml"
              echo ""
              echo "Done! Run 'rebuild' to apply changes."
            else
              echo "Adding a new secret requires two steps:"
              echo "1. Edit default.nix to define the secret path"
              echo "2. Edit secrets.yaml to add the encrypted value"
              echo ""
              read -p "Press Enter to open default.nix..."
              ''${EDITOR:-nvim} "$secrets_dir/default.nix"
              echo ""
              read -p "Press Enter to edit secrets.yaml..."
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

      _secrets_completions() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        local prev="''${COMP_WORDS[COMP_CWORD-1]}"
        local secrets="kubeconfig aws_credentials aws_config rclone_config"

        case "$prev" in
          edit|view)
            COMPREPLY=($(compgen -W "$secrets" -- "$cur"))
            ;;
          *)
            COMPREPLY=($(compgen -W "edit view add" -- "$cur"))
            ;;
        esac
      }
      complete -F _secrets_completions secrets

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
