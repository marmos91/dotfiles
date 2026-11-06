{ config, pkgs, lib, ... }:
let
  # Catppuccin Mocha palette for GNOME Terminal (not supported by catppuccin/nix).
  # Read from the flake input, as pi.nix does, so a catppuccin bump carries over.
  p =
    (builtins.fromJSON (
      builtins.readFile "${config.catppuccin.sources.palette}/palette.json"
    )).mocha.colors;
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
          foregroundColor = p.text.hex;
          backgroundColor = p.base.hex;
          cursor = {
            foreground = p.base.hex;
            background = p.rosewater.hex;
          };
          palette = [
            p.surface1.hex
            p.red.hex
            p.green.hex
            p.yellow.hex
            p.blue.hex
            p.pink.hex
            p.teal.hex
            p.subtext1.hex
            p.surface2.hex
            p.red.hex
            p.green.hex
            p.yellow.hex
            p.blue.hex
            p.pink.hex
            p.teal.hex
            p.subtext0.hex
          ];
        };
      };
    };
  };
}
