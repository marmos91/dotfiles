{
  pkgs,
  lib,
  config,
  ...
}:
let
  catppuccinK9S = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "k9s";
    rev = "fdbec82284744a1fc2eb3e2d24cb92ef87ffb8b4";
    sha256 = "0cs7j1z0xq66w0700qcrc6ynzmw3bdr422p1rnkl7hxq8g4a67zn";
  };
in
{
  programs.k9s = {
    enable = true;

    skins = {
      catppuccin-latte = "${catppuccinK9S}/dist/catppuccin-latte.yaml";
      catppuccin-frappe = "${catppuccinK9S}/dist/catppuccin-frappe.yaml";
      catppuccin-macchiato = "${catppuccinK9S}/dist/catppuccin-macchiato.yaml";
      catppuccin-mocha = "${catppuccinK9S}/dist/catppuccin-mocha.yaml";
      catppuccin-mocha-transparent = "${catppuccinK9S}/dist/catppuccin-mocha-transparent.yaml";
    };

    settings = {
      k9s = {
        ui = {
          skin = "catppuccin-mocha-transparent";
        };
      };
    };
  };

  home.sessionVariables = {
    K9S_CONFIG_DIR = "$HOME/Library/Application\ Support/k9s";
  };
}
