{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Text editors
    neovim
  ];
}
