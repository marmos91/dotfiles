{ lib, ... }:
{
  imports = [
    ./darwin.nix
    ./homebrew.nix
    ./preferences.nix
    ./security.nix
  ];
}
