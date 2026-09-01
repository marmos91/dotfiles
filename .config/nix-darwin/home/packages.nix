{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      # Fonts
      nerd-fonts.fira-code
      nerd-fonts.meslo-lg

      age
      ansible
      awscli2
      bazel-watcher
      bazelisk
      btop
      buildifier
      certbot
      cmake
      commitlint
      ffmpeg
      gh
      git-lfs
      goreleaser
      go-task
      hub
      jq
      kubectl
      kubectx
      kubernetes-helm
      luarocks
      markdownlint-cli
      fastfetch
      neovim
      opencode
      pi-coding-agent
      pulumi
      pulumiPackages.pulumi-go
      (scaleway-cli.overrideAttrs (_: { doCheck = false; }))
      sd
      sshpass
      stow
      swiftformat
      swiftlint
      tilt
      tldr
      tmuxinator
      watch
      wget
      wireguard-tools
      yq
      yt-dlp
      zstd
      # Custom scripts
      (pkgs.writeShellScriptBin "sync-nvim-remote" ''
        #!/usr/bin/env bash

        if [ -z "$1" ]; then
          echo "Usage: sync-nvim-remote user@host"
          exit 1
        fi

        HOST=$1

        echo "🔄 Syncing nvim configuration to $HOST..."

        # Sync nvim config
        ${pkgs.rsync}/bin/rsync -avz --delete \
          --exclude='.git' \
          --exclude='lazy-lock.json' \
          ~/.config/nvim/ $HOST:~/.config/nvim/

        if [ $? -eq 0 ]; then
          echo "✓ Sync complete!"
          echo "Connecting to $HOST..."
          ${pkgs.openssh}/bin/ssh $HOST
        else
          echo "✗ Sync failed!"
          exit 1
        fi
      '')

      # Restore SSH keys from 1Password onto disk. 1Password stays the store of
      # record (for a rebuild/new machine); the working copies in ~/.ssh mean
      # ssh and git signing never need an unlock or a fingerprint.
      #
      # Keys come out of 1Password without a passphrase, so anyone with read
      # access to ~/.ssh has them. That is the trade for no per-use prompt.
      (pkgs.writeShellScriptBin "op-ssh-restore" ''
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
      '')
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      reattach-to-user-namespace
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      # Note: 1Password should be installed via official apt repo for full SSH agent support
      # See: https://support.1password.com/install-linux/
      binutils
      docker
      gcc
      gnumake
      mesa
      wl-clipboard # Wayland clipboard (wl-copy/wl-paste)
      xclip # X11 clipboard
    ];
}
