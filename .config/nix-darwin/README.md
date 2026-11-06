# Nix-Darwin Modular Configuration

This is a modular nix-darwin configuration that manages both system-level and user-level settings.

```
~/.config/nix-darwin/
├── flake.nix                # Main flake configuration
├── system/                  # System-level configuration (nix-darwin)
│   ├── default.nix          # System imports
│   ├── darwin.nix           # Core Darwin config & Nix settings
│   ├── homebrew.nix         # Homebrew packages & casks
│   ├── preferences.nix      # macOS system preferences
│   └── security.nix         # Security settings
└── home/                    # User-level configuration (home-manager)
    ├── default.nix          # Home-manager entry point (also enables fontconfig)
    ├── env.nix              # Environment variables
    ├── packages.nix         # User packages, custom scripts, nerd-fonts
    ├── catppuccin.nix, claude.nix, agent-skills.nix
    ├── programs/            # terminal/, shell/ (zsh), git/, utilities/,
    │                        # desktop/ (GNOME), services/ (ssh), gnupg.nix
    ├── development/         # Language toolchains (bash, go, nix, node, python, rust)
    └── secrets/             # sops-nix, see secrets/README.md
```

## Usage

```bash
# Clone your dotfiles
git clone https://github.com/marmos91/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix (and, on Linux, 1Password/Docker), stow the dotfiles, then apply
# the configuration. install.sh pins the Determinate nix-installer GitHub
# release and verifies its published SHA-256 before executing it, and refuses
# to run Homebrew's unverified HEAD installer. The hashes live only in
# install.sh.
#
# macOS needs Homebrew first (https://brew.sh) for stow. Without it install.sh
# skips stowing and the configuration step, because ~/.config/nix-darwin only
# exists after `stow .`. In that case: install Homebrew, then re-run
# ./install.sh --skip-nix.
./install.sh
```

## Daily Usage

```bash
# Rebuild system after changes
rebuild  # (alias for sudo darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu)

# Update flake inputs
nix flake update ~/.config/nix-darwin

# Clean up Nix store
nix-gc  # (alias for nix-collect-garbage -d && nix-store --optimize)

# Search for packages
nix-search <package-name>
```
