{ pkgs, lib, ... }:
let
  # Catppuccin Mocha palette for GNOME Terminal (not supported by catppuccin/nix)
  catppuccin = {
    rosewater = "#f5e0dc";
    pink = "#f5c2e7";
    red = "#f38ba8";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    blue = "#89b4fa";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    surface2 = "#585b70";
    surface1 = "#45475a";
    base = "#1e1e2e";
  };
in
lib.mkIf pkgs.stdenv.isLinux {
  # GNOME Shell extensions
  home.packages = with pkgs.gnomeExtensions; [
    dash-to-dock
  ];

  # GNOME dconf settings for macOS-like experience
  dconf.settings = {
    # Enable installed extensions
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
      ];
    };

    # Keyboard repeat speed
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 200;
      repeat-interval = lib.hm.gvariant.mkUint32 15;
    };

    # Trackpad - natural scrolling and tap to click
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      speed = 0.5;
    };

    # Mouse - natural scrolling
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
      speed = 0.25;
    };

    # Interface - dark mode, fonts, clock, and hot corners
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-animations = true;
      font-antialiasing = "rgba";
      font-hinting = "slight";
      enable-hot-corners = true;
      clock-format = "24h";
      clock-show-weekday = true;
    };

    # Dock - macOS-like behavior (requires dash-to-dock extension)
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      dash-max-icon-size = lib.hm.gvariant.mkInt32 48;
      autohide = true;
      intellihide = true;
      dock-fixed = false; # Allow dock to hide
      show-trash = false;
      click-action = "minimize-or-previews";
    };

    # Window behavior - buttons on left like macOS
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "close,minimize,maximize:";
      focus-mode = "click";
    };

    # File manager - Finder-like behavior
    "org/gnome/nautilus/preferences" = {
      show-hidden-files = false;
      default-folder-viewer = "list-view";
    };
  };

  # GNOME Terminal with Catppuccin Mocha
  programs.gnome-terminal = {
    enable = true;
    themeVariant = "dark";
    profile = {
      "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        default = true;
        visibleName = "Catppuccin Mocha";
        font = "MesloLGS Nerd Font Mono 12";
        colors = {
          foregroundColor = catppuccin.text;
          backgroundColor = catppuccin.base;
          cursor = {
            foreground = catppuccin.base;
            background = catppuccin.rosewater;
          };
          palette = [
            catppuccin.surface1
            catppuccin.red
            catppuccin.green
            catppuccin.yellow
            catppuccin.blue
            catppuccin.pink
            catppuccin.teal
            catppuccin.subtext1
            catppuccin.surface2
            catppuccin.red
            catppuccin.green
            catppuccin.yellow
            catppuccin.blue
            catppuccin.pink
            catppuccin.teal
            catppuccin.subtext0
          ];
        };
      };
    };
  };
}
