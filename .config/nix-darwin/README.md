# Nix-Darwin Modular Configuration

This is a modular nix-darwin configuration that manages both system-level and user-level settings.

```
~/.config/nix-darwin/
├── flake.nix                # Main flake configuration
├── system/                  # System-level configuration (nix-darwin)
│   ├── default.nix         # System imports
│   ├── darwin.nix          # Core Darwin config & Nix settings
│   ├── homebrew.nix        # Homebrew packages & casks
│   ├── preferences.nix     # macOS system preferences
│   ├── fonts.nix          # Font configuration
│   └── security.nix       # Security settings
├── home/                   # User-level configuration (home-manager)
│   ├── default.nix        # Home-manager entry point
│   ├── programs/          # User programs
│   │   ├── terminal/      # Terminal applications
│   │   ├── shell/         # Shell configuration
│   │   ├── git/          # Git configuration
│   │   └── utilities/     # CLI utilities
│   ├── development/       # Development tools & environments
│   │   ├── languages/     # Language-specific configs
│   │   ├── tools/        # Development tools
│   │   └── environments/ # Dev environments (direnv, etc.)
│   ├── packages/         # Package collections
│   └── services/         # System services
└── lib/                  # Custom library functions
```

## Usage

```bash
# Install dependencies (if not already done)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

# Clone your dotfiles
git clone https://github.com/marmos91/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Apply stow configuration
stow .

# Build and apply nix-darwin configuration
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ~/.config/nix-darwin#amaterasu
```

## Daily Usage

```bash
# Rebuild system after changes
rebuild  # (alias for darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu)

# Update flake inputs
nix flake update ~/.config/nix-darwin

# Clean up Nix store
nix-gc  # (alias for nix-collect-garbage -d && nix-store --optimize)

# Search for packages
nix-search <package-name>
```
