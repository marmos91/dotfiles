{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt
    nil # Nix LSP
    nixd # Nix LSP used by pi-lens (evaluation via flake.nix)
    nix-tree
    nix-du
    nixpkgs-review
    nix-update
    # LSP servers pi-lens dispatches for nix files and shared tooling
    typescript-language-server
    bash-language-server
    vscode-html-languageserver # bin: vscode-html-language-server
    vscode-css-languageserver # bin: vscode-css-language-server
    vscode-json-languageserver # bin: vscode-json-language-server
    yaml-language-server
    taplo # TOML (also covers JSON fallback)
    lua-language-server # Lua LSP
    marksman # Markdown LSP
  ];
}
