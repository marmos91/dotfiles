{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;

  commonConfig = ''
    theme = Catppuccin Mocha
    font-family = MesloLGS Nerd Font Mono
    font-size = 13
    shell-integration-features = no-cursor,sudo,no-title

    mouse-hide-while-typing = true
    mouse-scroll-multiplier = 2

    window-padding-balance = true
    window-padding-x = 2
    confirm-close-surface = false
    clipboard-read = allow
    clipboard-write = allow

    keybind = shift+enter=text:\n
    keybind = ctrl+left_bracket=text:\x1b
  '';

  darwinConfig = ''
    window-colorspace = "display-p3"
    macos-titlebar-style = transparent
    background-blur-radius = 40
    background-opacity = 0.96
    macos-option-as-alt = true
  '';

  linuxConfig = ''
    gtk-titlebar = true
    window-decoration = true
  '';
in
{
  programs.ghostty = {
    enable = true;
    package = if isDarwin then null else pkgs.ghostty; # Use Cask on macOS, nixpkgs on Linux
    enableZshIntegration = true;
  };

  # macOS config location
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = lib.mkIf isDarwin {
    text = commonConfig + darwinConfig;
  };

  # Linux config location (XDG)
  xdg.configFile."ghostty/config" = lib.mkIf (!isDarwin) {
    text = commonConfig + linuxConfig;
  };
}
