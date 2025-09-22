{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Build systems
    bazelisk
    cmake
    go-task

    # Linters and formatters
    buildifier # Bazel formatter
    commitlint
    markdownlint-cli

    # Documentation
    neovim
    luarocks
  ];
}
