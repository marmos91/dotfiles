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
    shell-integration-features = no-cursor,sudo,no-title

    mouse-hide-while-typing = true
    mouse-scroll-multiplier = 2

    window-padding-balance = true
    window-padding-x = 2
    window-colorspace = "display-p3"
    macos-titlebar-style = transparent
    background-blur-radius = 40
    background-opacity = 0.96

    macos-option-as-alt = true
    confirm-close-surface = false
    clipboard-read = allow
    clipboard-write = allow
  '';
}
