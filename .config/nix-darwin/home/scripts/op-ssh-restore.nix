# Restore SSH keys from 1Password onto disk. 1Password stays the store of
# record (for a rebuild/new machine); the working copies in ~/.ssh mean
# ssh and git signing never need an unlock or a fingerprint.
#
# Keys come out of 1Password without a passphrase, so anyone with read
# access to ~/.ssh has them. That is the trade for no per-use prompt.
{ pkgs }:
pkgs.writeShellScriptBin "op-ssh-restore" ''
  set -euo pipefail

  VAULT="''${OP_SSH_VAULT:-Private}"
  force=0
  dry=0
  only=""
  for arg in "$@"; do
    case "$arg" in
      --force) force=1 ;;
      --dry-run) dry=1 ;;
      -*) echo "usage: op-ssh-restore [--force] [--dry-run] [key...]" >&2; exit 1 ;;
      # Bare names limit the run to those keys; default is all of them.
      *) only="$only $arg" ;;
    esac
  done

  command -v op >/dev/null || { echo "op (1Password CLI) not found" >&2; exit 1; }

  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  op item list --categories "SSH Key" --vault "$VAULT" --format json \
    | ${pkgs.jq}/bin/jq -r '.[].title' \
    | while IFS= read -r title; do
        dest="$HOME/.ssh/$title"

        if [ -n "$only" ] && [[ " $only " != *" $title "* ]]; then
          continue
        fi
        if [ -e "$dest" ] && [ "$force" -eq 0 ]; then
          echo "skip    $title (exists — --force to replace)"
          continue
        fi
        if [ "$dry" -eq 1 ]; then
          echo "would restore $title -> $dest"
          continue
        fi

        # Keep a copy of whatever was there; these are the only copies of
        # keys that predate 1Password.
        [ -e "$dest" ] && cp -p "$dest" "$dest.bak"

        ( umask 077
          op read "op://$VAULT/$title/private key?ssh-format=openssh" > "$dest" )
        ${pkgs.openssh}/bin/ssh-keygen -yf "$dest" > "$dest.pub"
        chmod 600 "$dest"
        chmod 644 "$dest.pub"
        echo "restored $title"
      done
''
