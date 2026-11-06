{ pkgs, ... }:
{
  programs.bat = {
    enable = true;

    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batpipe
      batwatch
    ];

    # Theme is managed by catppuccin/nix module (see home/catppuccin.nix)

    config = {
      pager = "less -FR";
    };
  };
}
