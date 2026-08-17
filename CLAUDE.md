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

# Garbage collection — normally unnecessary; determinate-nixd collects in the
# background (determinateNix.determinateNixd.garbageCollector.strategy)
nix-gc                     # alias for nix-collect-garbage -d && nix-store --optimize

# Restore SSH keys from 1Password into ~/.ssh (new machine, or after rotating)
op-ssh-restore [--force] [--dry-run] [key...]

# Search for packages
nix-search <package>       # alias for nix search nixpkgs

# Initial setup (fresh install)
chmod +x ~/.dotfiles/install.sh && ~/.dotfiles/install.sh

# Uninstall
chmod +x ~/.dotfiles/uninstall.sh && ~/.dotfiles/uninstall.sh

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

Casks and brews from a third-party tap **must be tap-qualified**
(`nikitabobko/tap/aerospace`, not `aerospace`). `brew bundle --cleanup` rewrites
Homebrew's trust store from the generated Brewfile, and an unqualified name
resolves to the core cask — leaving the tap's version untrusted, which makes
`brew cleanup` exit 1 and fails the whole activation.

`onActivation.autoUpdate`/`upgrade` are deliberately `false`: non-deterministic
third-party upgrades during activation made `rebuild` slow, interactive, and
able to fail on unrelated brew errors. Run `brew update && brew upgrade` manually.

### Changing Nix settings
Not via `nix.settings` — the determinate module sets `nix.enable = mkForce false`,
so nix-darwin never writes it and the setting is silently dropped. Use
`determinateNix.customSettings` (freeform nix.conf) in `system/darwin.nix`, and
`determinateNix.determinateNixd.*` for daemon behaviour such as GC.

Prefer `extra-substituters` / `extra-trusted-public-keys`; the plain forms
*replace* Determinate's own lists. Determinate already owns
`experimental-features`, `max-jobs`, `sandbox`, `netrc-file` and `ssl-cert-file` —
don't restate them.

### Adding a new Nix package
Edit `.config/nix-darwin/home/packages.nix` or the relevant program file, then run `rebuild`.

### Adding a Neovim plugin
Create a new file in `.config/nvim/lua/plugins/`, Lazy.nvim auto-discovers it.

### Adding shell aliases
Edit `.config/nix-darwin/home/programs/shell/zsh.nix` in the `shellAliases` section.

## Commit Guidelines

- Always sign commits (`git commit -S`) when possible
- Never mention Claude Code, AI tools, or co-authored-by AI in commit messages or PR descriptions
- Keep commit messages concise

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
