{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    # Go tools
    golangci-lint
    gopls # Go language server
    gofumpt # gopls shells out to it (gopls.gofumpt = true)
    delve # Debugger
  ];
}
