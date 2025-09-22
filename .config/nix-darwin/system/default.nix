{ lib, ... }: {
  imports = [
    ./darwin.nix
    ./homebrew.nix
    ./preferences.nix
    ./fonts.nix
    ./security.nix
  ];
}
