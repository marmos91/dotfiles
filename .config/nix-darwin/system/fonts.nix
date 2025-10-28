{ pkgs, ... }:
{
  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.meslo-lg
  ];
}
