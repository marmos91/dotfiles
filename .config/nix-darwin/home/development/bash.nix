{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shfmt
    ast-grep
  ];
}
