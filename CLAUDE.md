# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for macOS using Nix Darwin, Home Manager, and GNU Stow. Manages system configuration, development environment, and editor setup declaratively.

## Key Commands

```bash
# System rebuild (after config changes)
rebuild                    # alias for darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu

# Full command if alias unavailable
darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu

# Update flake inputs
nix flake update ~/.config/nix-darwin

# Garbage collection
nix-gc                     # alias for nix-collect-garbage -d && nix-store --optimize

# Search for packages
nix-search <package>       # alias for nix search nixpkgs

# Initial setup (fresh install)
chmod +x ~/.dotfiles/setup.sh && ~/.dotfiles/setup.sh

# Re-stow dotfiles after adding new configs
stow .
```

## Architecture

### Nix Darwin Configuration (`.config/nix-darwin/`)

```
flake.nix                    # Main entry point, defines inputs and outputs
├── system/                  # System-level (nix-darwin)
│   ├── darwin.nix          # Core Nix settings, system packages
│   ├── homebrew.nix        # Homebrew casks and packages
│   ├── preferences.nix     # macOS system preferences
│   ├── fonts.nix           # Font configuration
│   └── security.nix        # Security settings
└── home/                    # User-level (home-manager)
    ├── env.nix             # Environment variables
    ├── packages.nix        # User packages and custom scripts
    ├── programs/           # Shell, terminal, git, utilities
    │   ├── terminal/       # ghostty, tmux, starship, atuin
    │   ├── shell/          # zsh (primary), fish
    │   ├── git/            # git config, lazygit
    │   └── utilities/      # bat, fzf, eza, ripgrep, etc.
    └── development/        # Language toolchains
        ├── go.nix, python.nix, rust.nix, node.nix, bash.nix, nix.nix
```

**Key settings:**
- Hostname: `amaterasu`
- System: `aarch64-darwin` (Apple Silicon)
- Uses Determinate Nix with flakes enabled

### Neovim Configuration (`.config/nvim/`)

```
init.lua                     # Entry point
└── lua/
    ├── options.lua         # Vim settings (leader=space, relative numbers)
    ├── keymaps.lua         # Custom keybindings
    ├── autocmds.lua        # Autocommands
    ├── lazy-bootstrap.lua  # Lazy.nvim bootstrap
    ├── lazy-plugins.lua    # Plugin manager setup
    └── plugins/            # Individual plugin configs (46 plugins)
```

**LSP servers configured:** bashls, gopls, pylsp, vtsls, lua_ls, marksman, taplo, terraformls, yamlls, jsonls, html, cssls, dockerls, starlark_rust, helm_ls (Rust uses rustaceanvim)

**Formatters:** stylua, black, gofumpt, shfmt, prettierd, taplo, buildifier

### Stow Structure

Files in `.dotfiles/` are symlinked to `~` via Stow. The `.stowrc` configures target as home and ignores setup scripts.

## Making Changes

### Adding a new Homebrew cask
Edit `.config/nix-darwin/system/homebrew.nix`, add to `casks` list, then run `rebuild`.

### Adding a new Nix package
Edit `.config/nix-darwin/home/packages.nix` or the relevant program file, then run `rebuild`.

### Adding a Neovim plugin
Create a new file in `.config/nvim/lua/plugins/`, Lazy.nvim auto-discovers it.

### Adding shell aliases
Edit `.config/nix-darwin/home/programs/shell/zsh.nix` in the `shellAliases` section.

## Commit Guidelines

- Don't mention Claude Code in commits or PRs
- Keep commit messages concise
