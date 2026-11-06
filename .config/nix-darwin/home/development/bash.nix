{ config, pkgs, hostname, username, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  home.packages = with pkgs; [
    shfmt
    ast-grep

    # `secrets edit <key>` lives in one script rather than in each shell's
    # function: bash has no function-scoped trap — a RETURN trap stays
    # installed and re-fires on every later call of any function. `sops set`
    # does the decrypt → patch → re-encrypt, so no plaintext copy of the whole
    # file is written; it rewrites its target in place, so it works on a copy
    # that is renamed over secrets.yaml only on success.
    (writeShellScriptBin "secrets-edit" ''
      set -euo pipefail

      secrets_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/nix-darwin/home/secrets"
      f="$secrets_dir/secrets.yaml"
      key="''${1:-}"

      # No key: edit the whole file, as before.
      if [ -z "$key" ]; then
        exec sops "$f"
      fi

      tmp=$(mktemp)
      # Same dir so the mv is a rename; .yaml suffix because sops picks the
      # format from the extension.
      new="$secrets_dir/.secrets-edit.yaml"
      trap 'rm -f "$tmp" "$new"' EXIT
      # `sops set` creates a missing key instead of failing, so read the current
      # value first: that is what rejects a typo.
      if ! sops -d --extract "[\"$key\"]" "$f" > "$tmp" 2>/dev/null; then
        echo "Secret '$key' not found" >&2
        exit 1
      fi
      "''${EDITOR:-nvim}" "$tmp"
      # JSON-encode the file contents so multi-line values stay strings and the
      # editor's trailing newline is dropped.
      cp "$f" "$new"
      ${pkgs.jq}/bin/jq -Rs 'rtrimstr("\n")' "$tmp" | sops set --value-stdin "$new" "[\"$key\"]"
      mv "$new" "$f"
      echo "Secret '$key' updated"
    '')
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
            # The body lives in the `secrets-edit` script (home.packages) so
            # bash and zsh share one implementation.
            secrets-edit "''${2:-}"
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

      flake-update() {
        echo "Updating flake inputs..."
        nix flake update --flake ~/.config/nix-darwin
        echo ""
        echo "Done! Run 'rebuild' to apply updates."
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
