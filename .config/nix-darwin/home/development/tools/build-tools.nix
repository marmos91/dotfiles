{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Build systems
    bazel-watcher
    bazelisk
    cmake
    go-task

    # Linters and formatters
    buildifier # Bazel formatter
    commitlint
    markdownlint-cli

    # Documentation
    luarocks
  ];
}
