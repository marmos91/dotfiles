{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."tmuxinator/dotfiles.yaml".text = ''
    name: dotfiles
    root: ~/.dotfiles

    windows:
      - editor:
          layout: main-vertical
          panes:
            - nvim .
  '';

  programs.zsh.shellAliases = {
    tx = "tmuxinator";
    txs = "tmuxinator start";
    txe = "tmuxinator edit";
    txl = "tmuxinator list";
  };
}
