# Shell-script toolchain. The bash shell itself is programs/shell/bash.nix.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shfmt
    ast-grep
    (import ../scripts/secrets-edit.nix { inherit pkgs; })
  ];
}
