# Edit one secret without decrypting the whole store to a fixed path, and
# without ever replacing it with plaintext. Shared by zsh and bash.
{ pkgs }:
pkgs.writeShellScriptBin "secrets" ''
  set -u

  # The store lives in the stowed dotfiles checkout, next to its .sops.yaml.
  secrets_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/nix-darwin/home/secrets"
  store="$secrets_dir/secrets.yaml"

  tmp_dir=""
  # Plaintext never outlives the command, including on Ctrl-C in $EDITOR.
  cleanup() { [ -n "$tmp_dir" ] && rm -rf "$tmp_dir"; }
  trap cleanup EXIT
  trap 'cleanup; exit 130' INT TERM HUP

  case "''${1:-}" in
    edit)
      # One implementation for both shells: secrets-edit
      # (scripts/secrets-edit.nix) edits a copy and renames it into place.
      exec secrets-edit "''${2:-}"
      ;;
    view)
      if [ -n "''${2:-}" ]; then
        exec sops -d --extract "[\"$2\"]" "$store"
      fi
      exec sops -d "$store"
      ;;
    add)
      if [ -n "''${2:-}" ] && [ -z "''${3:-}" ]; then
        echo "Usage: secrets add <name> <path>" >&2
        exit 1
      fi
      if [ -n "''${2:-}" ]; then
        echo "Adding secret: $2 -> $3"
        echo ""
        echo "Step 1: add this to the secrets block of default.nix:"
        echo "      $2 = mk \"$3\";"
        printf 'Press Enter to open default.nix... '
      else
        echo "Adding a new secret requires two steps:"
        echo "1. Edit default.nix to define the secret path"
        echo "2. Edit secrets.yaml to add the encrypted value"
        echo ""
        printf 'Press Enter to open default.nix... '
      fi
      read -r _
      ''${EDITOR:-nvim} "$secrets_dir/default.nix"
      echo ""
      printf 'Press Enter to edit secrets.yaml... '
      read -r _
      exec sops "$store"
      ;;
    *)
      echo "Usage: secrets <command> [args]"
      echo ""
      echo "Commands:"
      echo "  edit [name]       Edit secrets (all or specific)"
      echo "  view [name]       View decrypted secrets (all or specific)"
      echo "  add [name path]   Add a new secret"
      exit 1
      ;;
  esac
''
