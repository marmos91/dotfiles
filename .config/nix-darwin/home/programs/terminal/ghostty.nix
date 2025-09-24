{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null; # Use the Cask version

    enableZshIntegration = true;
  };

  home.file."Library/Application Support/com.mitchellh.ghostty/config".text = ''
    theme = Catppuccin Mocha
    font-family = MesloLGS Nerd Font Mono
    font-size = 13
    macos-option-as-alt = true
    background-opacity = 0.96
    background-blur-radius = 40
    confirm-close-surface = false
    mouse-hide-while-typing = true
    macos-titlebar-style = tabs
  '';
}
