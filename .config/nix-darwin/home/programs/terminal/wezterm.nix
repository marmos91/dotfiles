{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    extraConfig = ''
      local config = wezterm.config_builder()


      -- Theme
      config.color_scheme = "Catppuccin Mocha"

      -- Font
      config.font = wezterm.font("MesloLGS Nerd Font Mono")
      config.font_size = 13

      -- Window
      config.initial_cols = 140
      config.initial_rows = 40
      config.window_padding = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
      }
      config.window_close_confirmation = "NeverPrompt"
      config.hide_tab_bar_if_only_one_tab = true

      -- Mouse
      config.hide_mouse_cursor_when_typing = true
      config.scrollback_lines = 10000

      -- Fallback to WebGpu if EGL fails
      config.front_end = "WebGpu"
      config.webgpu_power_preference = "LowPower"

      -- Cursor
      config.default_cursor_style = "SteadyBlock"

      ${lib.optionalString isDarwin ''
      -- macOS specific
      config.window_decorations = "RESIZE"
      config.window_background_opacity = 0.96
      config.macos_window_background_blur = 40
      config.send_composed_key_when_left_alt_is_pressed = false
      config.send_composed_key_when_right_alt_is_pressed = false
      ''}

      ${lib.optionalString isLinux ''
      -- Linux/Ubuntu specific
      config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
      config.window_background_opacity = 0.92
      config.enable_wayland = true
      ''}

      -- Keybindings (matching ghostty)
      config.keys = {
        { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
        { key = "[", mods = "CTRL", action = wezterm.action.SendString("\x1b") },
      }

      return config
    '';
  };
}
