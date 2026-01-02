{ ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = true;
        nerdFontsVersion = "3";
        theme = {
          # Catppuccin Mocha (Blue accent)
          # https://github.com/catppuccin/lazygit
          activeBorderColor = [ "#89b4fa" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#89b4fa" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
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
