{ ... }: {
  programs.k9s = {
    enable = true;
    settings = { k9s = { ui = { skin = "catppuccin-mocha"; }; }; };
  };
}

