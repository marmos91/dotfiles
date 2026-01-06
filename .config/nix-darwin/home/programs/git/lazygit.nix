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
        pager = {
          diff = "delta --dark --paging=never";
          log = "delta --dark --paging=never";
          show = "delta --dark --paging=never";
        };
      };
      os = {
        editPreset = "nvim";
      };
    };
  };
}
