{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.kitty = {
    enable = true;
    # Theme is managed by catppuccin/nix module (see home/catppuccin.nix)

    font = {
      name = "MesloLGS Nerd Font Mono";
      size = 13;
    };

    settings = {
      # Window
      window_padding_width = 2;
      confirm_os_window_close = 0;
      hide_window_decorations = lib.mkIf isDarwin "titlebar-only";
      background_opacity = lib.mkIf isDarwin "0.96";
      background_blur = lib.mkIf isDarwin 40;

      # Mouse
      mouse_hide_wait = "2.0";

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 0;

      # Shell integration
      shell_integration = "enabled";

      # Clipboard
      clipboard_control = "write-clipboard read-clipboard write-primary read-primary";

      # macOS specific
      macos_option_as_alt = lib.mkIf isDarwin true;
      macos_colorspace = lib.mkIf isDarwin "displayp3";
    };

    keybindings = {
      "shift+enter" = "send_text all \\n";
      "ctrl+left_bracket" = "send_text all \\x1b";
    };

    shellIntegration = {
      enableZshIntegration = true;
    };
  };
}
