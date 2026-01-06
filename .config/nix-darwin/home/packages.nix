{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
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
    claude-code
    cmake
    commitlint
    ffmpeg
    gh
    git-lfs
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
    sd
    sshpass
    stow
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
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    reattach-to-user-namespace
  ] ++ lib.optionals pkgs.stdenv.isLinux [
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
