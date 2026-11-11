# Aliases and functions shared by zsh.nix and bash.nix. Not a module: both
# import it and add their own completion glue and shell-only extras.
{ pkgs, hostname, username }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  aliases = {
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

    # The GitHub MCP plugin reads GITHUB_PERSONAL_ACCESS_TOKEN; scope it to
    # claude instead of exporting it to every process.
    # On darwin, claude-mimir (utilities/claude-mimir.nix) adds it-router under
    # headroom so Mimir models work; it exports the token itself.
    claude =
      if isDarwin then
        "claude-mimir --memory --code-graph"
      else
        "GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token 2>/dev/null) headroom wrap claude --memory --code-graph";

    # Directory shortcuts
    dotfiles = "cd ~/.dotfiles";
    config = "cd ~/.config";
  };

  functions = ''
    # Development helpers
    mkcd() { mkdir -p "$1" && cd "$1"; }

    # Nix helpers
    nix-shell-p() { nix-shell -p "$@"; }
    nix-run() { nix run nixpkgs#"$1" -- "''${@:2}"; }

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
}
