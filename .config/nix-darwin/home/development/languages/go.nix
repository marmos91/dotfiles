{ pkgs, ... }: {
  home.packages = with pkgs; [
    go
    # Go tools
    golangci-lint
    gopls # Go language server
    delve # Debugger
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };
}
