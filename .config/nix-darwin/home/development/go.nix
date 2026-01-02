{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    # Go tools
    golangci-lint
    gopls # Go language server
    delve # Debugger
  ];
}
