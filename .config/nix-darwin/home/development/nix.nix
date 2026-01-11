{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt
    nil # Nix LSP
    nix-tree
    nix-du
    nixpkgs-review
    nix-update
  ];
}
