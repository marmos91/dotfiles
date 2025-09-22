{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil # Nix LSP
    nix-tree
    nix-du
    nixpkgs-review
    nix-update
  ];
}
