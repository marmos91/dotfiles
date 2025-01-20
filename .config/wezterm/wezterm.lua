
local wezterm = require("wezterm")

local config = {
    term = "xterm-256color",
    color_scheme = "Catppuccin Mocha",
    font = wezterm.font("MesloLGS Nerd Font"),
    font_size = 13,
    front_end = "OpenGL",
    freetype_load_flags = "NO_HINTING",
    freetype_load_target = "HorizontalLcd",
    enable_tab_bar = false,
    use_fancy_tab_bar = false,
    tab_bar_at_bottom = false,
    window_close_confirmation = "NeverPrompt",
    keys = {
        {
            key = "n",
            mods = "SHIFT|CTRL",
            action = wezterm.action.ToggleFullScreen,
        },
    },
    mouse_bindings = {
        -- Ctrl-click will open the link under the mouse cursor
        {
            event = { Up = { streak = 1, button = 'Left' } },
            mods = 'CTRL',
            action = wezterm.action.OpenLinkAtMouseCursor,
        },
    },
    initial_rows = 40,
    initial_cols = 133,
    window_padding = {
        left = 15,
        right = 15,
        top = 15,
        bottom = 15,
    },
    default_prog = { "/etc/profiles/per-user/marmos91/bin/fish" },
    window_decorations = "RESIZE",
}

return config
