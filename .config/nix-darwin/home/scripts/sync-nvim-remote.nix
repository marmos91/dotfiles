{ pkgs }:
pkgs.writeShellScriptBin "sync-nvim-remote" ''
  #!/usr/bin/env bash

  if [ -z "$1" ]; then
    echo "Usage: sync-nvim-remote user@host"
    exit 1
  fi

  # A host starting with - would be read as an rsync/ssh option (and
  # `-e` runs a local command); anything outside the pattern would split
  # into extra words. `@` must stay allowed: user@host is the usage, and
  # `[]:` for IPv6 literals (user@[::1]).
  case "$1" in
    -*|*[!]A-Za-z0-9._@:[-]*) echo "Invalid host: $1" >&2; exit 2 ;;
  esac

  HOST=$1

  echo "🔄 Syncing nvim configuration to $HOST..."

  # Sync nvim config
  ${pkgs.rsync}/bin/rsync -avz --delete \
    --exclude='.git' \
    --exclude='lazy-lock.json' \
    -- "$HOME/.config/nvim/" "$HOST:~/.config/nvim/"

  if [ $? -eq 0 ]; then
    echo "✓ Sync complete!"
    echo "Connecting to $HOST..."
    ${pkgs.openssh}/bin/ssh "$HOST"
  else
    echo "✗ Sync failed!"
    exit 1
  fi
''
