{ pkgs, lib, config, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;

  commonSettings = {
    # theme is managed by the catppuccin nix module (see home/catppuccin.nix)
    font-family = "MesloLGS Nerd Font Mono";
    font-size = 13;
    shell-integration-features = "no-cursor,sudo,no-title";

    mouse-hide-while-typing = true;
    mouse-scroll-multiplier = 2;

    window-padding-balance = true;
    window-padding-x = 2;
    confirm-close-surface = false;
    clipboard-read = "allow";
    clipboard-write = "allow";

    keybind = [
      "shift+enter=text:\\n"
      "ctrl+left_bracket=text:\\x1b"
    ];
  };

  darwinSettings = {
    window-colorspace = "display-p3";
    macos-titlebar-style = "transparent";
    background-blur-radius = 40;
    background-opacity = 0.96;
    macos-option-as-alt = true;
  };

  linuxSettings = {
    gtk-titlebar = true;
    window-decoration = true;
  };
in
{
  programs.ghostty = {
    enable = true;
    package = if isDarwin then null else pkgs.ghostty; # Use Cask on macOS, nixpkgs on Linux
    enableZshIntegration = true;
    settings = commonSettings // (if isDarwin then darwinSettings else linuxSettings);
  };

  # On macOS, the Ghostty Cask reads from ~/Library/Application Support/...
  # Symlink it to the home-manager-managed XDG config so there is one source of truth
  # and the catppuccin module's theme override applies cleanly.
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = lib.mkIf isDarwin {
    source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/ghostty/config";
  };
}
