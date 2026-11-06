# Shell helpers sourced by both zsh (programs/shell/zsh.nix) and bash
# (development/bash.nix), so the two shells share one copy.
{ pkgs, hostname, username }:
pkgs.writeText "shell-functions.sh" ''
  mkcd() { mkdir -p "$1" && cd "$1"; }

  nix-shell-p() { nix-shell -p "$@"; }
  nix-run() { nix run nixpkgs#"$1" -- "''${@:2}"; }

  flake-update() {
    echo "Updating flake inputs..."
    nix flake update --flake ~/.config/nix-darwin
    echo ""
    echo "Done! Run 'rebuild' to apply updates."
  }

  rebuild() {
    ${if pkgs.stdenv.hostPlatform.isDarwin then ''
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
''
