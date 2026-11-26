{ pkgs, lib, ... }:
{
  # gh discovers extensions by scanning its data dir, so linking the nixpkgs
  # binary there is what makes `gh dash` work (upstream does this via
  # `gh extension install`). xdg.dataFile honours XDG_DATA_HOME, which go-gh
  # reads — a hardcoded ~/.local/share would break if that were ever exported.
  xdg.dataFile."gh/extensions/gh-dash/gh-dash".source = "${pkgs.gh-dash}/bin/gh-dash";

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
      gitleaks # secret scan before a push or a posted review (secret-scan skill)
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
      # semgrep pins itself to mcp 1.x via pythonPackages.overrideScope upstream.
      semgrep
      sshpass
      stow
      swiftformat
      swiftlint
      tilt
      tldr
      tmuxinator
      uv # Python package runner; drives the mempalace MCP server (mcp.nix / claude.nix)
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
