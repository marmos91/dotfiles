# Global Catppuccin theme configuration
# Uses the official catppuccin/nix flake for consistent theming across all tools
{ ... }:
{
  # Global Catppuccin settings
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";

    # Per-program enablement
    bat.enable = true;
    btop.enable = true;
    delta.enable = true;
    fzf.enable = true;
    k9s.enable = true;
    kitty.enable = true;
    lazygit.enable = true;
    starship.enable = true;
    # tmux uses manual plugin config for custom status bar (see terminal/tmux.nix)
    zsh-syntax-highlighting.enable = true;
  };
}
