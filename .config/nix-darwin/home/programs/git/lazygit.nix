{ ... }:
{
  programs.lazygit = {
    enable = true;
    # Theme is managed by catppuccin/nix module (see home/catppuccin.nix)
    settings = {
      gui = {
        showIcons = true;
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
      os = {
        editPreset = "nvim";
      };
    };
  };
}
