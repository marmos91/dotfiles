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
      buildifier
      certbot
      cmake
      commitlint
      ffmpeg
      gh
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
    ]
    # Custom scripts, one file each.
    ++ map (f: import f { inherit pkgs; }) [
      ./scripts/sync-nvim-remote.nix
      ./scripts/op-ssh-restore.nix
      ./scripts/secrets.nix
      ./scripts/reap.nix
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
