# Nix-Darwin Modular Configuration

This is a modular nix-darwin configuration that manages both system-level and user-level settings.

```
~/.config/nix-darwin/
├── flake.nix                # Inputs; darwin (amaterasu) and Linux home-manager outputs
├── system/                  # System-level configuration (nix-darwin)
│   ├── default.nix          # System imports
│   ├── darwin.nix           # User home, Determinate Nix settings, system packages
│   ├── homebrew.nix         # Homebrew taps, brews & casks
│   ├── preferences.nix      # macOS system preferences, Dock
│   └── security.nix         # Touch ID sudo, firewall, screensaver lock
└── home/                    # User-level configuration (home-manager)
    ├── default.nix          # Home-manager entry point
    ├── env.nix              # Session variables and PATH
    ├── packages.nix         # User packages
    ├── scripts/             # One writeShellScriptBin per file (secrets, reap, ...)
    ├── catppuccin.nix       # Theme
    ├── claude.nix           # Claude Code (nixpkgs)
    ├── agent-skills.nix     # Agent skill packs (pstack, marmos91/skills)
    ├── secrets/             # sops-nix secrets (see secrets/README.md)
    ├── development/         # Toolchains: go, python, rust, node, nix, shell scripts
    └── programs/
        ├── shell/           # zsh, bash, and the aliases/functions they share
        ├── terminal/        # ghostty, tmux, tmuxinator, starship, atuin, carapace
        ├── git/             # git, lazygit
        ├── gnupg.nix        # ~/.gnupg
        ├── services/        # ssh
        ├── desktop/         # GNOME (Linux)
        └── utilities/       # CLI tools, AI agents (pi, opencode, headroom, mcp), obsidian
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
