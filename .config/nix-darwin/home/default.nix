{ pkgs, ... }:
{
  imports = [
    ./programs
    ./development
    ./env.nix
    ./packages.nix
    ./catppuccin.nix
  ];

  # Enable desktop integration on non-NixOS Linux (Ubuntu, etc.)
  targets.genericLinux.enable = pkgs.stdenv.isLinux;

  # Make Nix-installed fonts available to system fontconfig (for native terminal apps)
  fonts.fontconfig.enable = true;

  # Ensure XDG directories are set up
  xdg.enable = true;
}
