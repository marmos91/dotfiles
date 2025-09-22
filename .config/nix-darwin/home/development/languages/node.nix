{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    pnpm
  ];

  home.sessionVariables = {
    PNPM_HOME = "$HOME/Library/pnpm";
  };
}
