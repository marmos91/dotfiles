{ pkgs, ... }:
{
  imports = [
    ./programs
    ./development
    ./secrets
    ./env.nix
    ./packages.nix
    ./catppuccin.nix
    ./claude.nix
    ./homebrew-trust.nix
  ];

  # Enable desktop integration on non-NixOS Linux (Ubuntu, etc.)
  targets.genericLinux.enable = pkgs.stdenv.isLinux;

  # Make Nix-installed fonts available to system fontconfig (for native terminal apps)
  fonts.fontconfig.enable = true;

  # Ensure XDG directories are set up
  xdg.enable = true;

  # HM 26.05 vs nixpkgs-unstable 26.11 — HM hasn't bumped yet
  home.enableNixpkgsReleaseCheck = false;
}
