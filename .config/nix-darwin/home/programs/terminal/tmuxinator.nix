{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."tmuxinator/.keep".text = "";

  xdg.configFile."tmuxinator/dotfiles.yaml".text = ''
    name: dotfiles
    root: ~/.dotfiles

    windows:
      - editor:
          layout: main-vertical
          panes:
            - nvim .
       
      - rebuild:
          panes:
            - # rebuild command ready
  '';

  programs.zsh.shellAliases = {
    tx = "tmuxinator";
    txs = "tmuxinator start";
    txe = "tmuxinator edit";
    txl = "tmuxinator list";
  };
}
