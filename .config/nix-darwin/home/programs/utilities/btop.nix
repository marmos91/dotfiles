{ ... }:
{
  programs.btop = {
    enable = true;

    # Theme is managed by catppuccin/nix module (see home/catppuccin.nix)

    settings = {
      theme_background = false;
      vim_keys = true;
      rounded_corners = true;
    };
  };
}
