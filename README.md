# marmos91 dotfiles

Cross-platform dotfiles for **macOS** and **Linux** (Ubuntu/GNOME), powered by Nix, Home Manager, and Stow.

![result](./assets/setup.png)

## Highlights

- **Cross-platform**: Works on macOS (Apple Silicon & Intel) and Linux (x86_64 & aarch64)
- **Declarative configuration**: Managed with [Nix Darwin](https://github.com/LnL7/nix-darwin) (macOS) and [Home Manager](https://github.com/nix-community/home-manager) (Linux)
- **Consistent theming**: [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) across all tools via [catppuccin/nix](https://github.com/catppuccin/nix)
- **Terminal emulators**: [Ghostty](https://github.com/ghostty-org/ghostty), [Kitty](https://sw.kovidgoyal.net/kitty/), [Wezterm](https://wezfurlong.org/wezterm/index.html)
- **Shell**: Zsh with [Starship](https://starship.rs/) prompt
- **Editor**: [Neovim](https://neovim.io/) with custom Lua configuration
- **Terminal multiplexer**: [Tmux](https://github.com/tmux/tmux/wiki) with catppuccin theme

## Installation

Clone the repository:

```bash
git clone https://github.com/marmos91/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Run the install script:

```bash
chmod +x install.sh && ./install.sh
```

### Options

| Flag | Description |
|------|-------------|
| `--shell <shell>` | Set default shell (`zsh` or `bash`). Default: `zsh` |
| `--shell-only` | Only change the default shell, skip full installation |
| `--hostname <name>` | Set hostname (macOS only). Default: `amaterasu` |
| `--no-stow` | Skip stowing dotfiles |
| `--skip-nix` | Skip Nix installation (use existing Nix) |
| `--no-1password` | Skip 1Password installation (Linux only) |
| `--help` | Show help message |

**Examples:**

```bash
./install.sh                          # Full install with defaults
./install.sh --shell bash             # Install with bash as default shell
./install.sh --hostname myhost        # Install with custom hostname (macOS)
./install.sh --shell-only             # Only set zsh as default (skip install)
./install.sh --no-stow --skip-nix     # Only apply Nix configuration
./install.sh --no-1password           # Skip 1Password installation on Linux
```

### What it does

1. Install [Stow](https://www.gnu.org/software/stow/) (via Homebrew on macOS, apt/dnf/pacman on Linux)
2. Install [Nix](https://nixos.org/) using the [Determinate Systems installer](https://determinate.systems/nix-installer/)
3. Install [1Password](https://1password.com/) via official apt repository (Linux only, for SSH agent)
4. Symlink dotfiles to your home directory via Stow
5. Apply the appropriate Nix configuration:
   - **macOS**: nix-darwin + home-manager
   - **Linux**: standalone home-manager
6. Set the default shell (Linux only)

### 1Password SSH Agent Setup

This configuration uses 1Password for SSH key management and Git commit signing. After installation:

1. **Open 1Password** and sign in to your account
2. **Enable SSH Agent**: Go to **Settings → Developer** and enable:
   - "Use the SSH agent"
   - "Integrate with 1Password CLI"
3. **Add your SSH key** to 1Password (if not already there)
4. **Authorize the key** for Git signing when prompted

The git configuration automatically uses 1Password's `op-ssh-sign` for commit signing:
- **macOS**: `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`
- **Linux**: `/opt/1Password/op-ssh-sign`

To verify it's working:

```bash
# Test SSH agent
ssh-add -l

# Test commit signing
echo "test" | git commit --allow-empty -m "Test signed commit"
git log --show-signature -1
```

**Note**: On macOS, install 1Password from the [Mac App Store](https://apps.apple.com/app/1password-7-password-manager/id1333542190) or [official download](https://1password.com/downloads/mac/).

### Post-install

Restart your terminal or log out/in for all changes to take effect.

## Uninstallation

To completely remove the dotfiles and Nix:

```bash
chmod +x uninstall.sh && ./uninstall.sh
```

### Options

| Flag | Description |
|------|-------------|
| `--dotfiles-only` | Only unstow dotfiles, keep Nix and packages |
| `--keep-nix` | Keep Nix installed, remove dotfiles and config |
| `--keep-stow` | Keep stow installed |
| `-y, --yes` | Skip confirmation prompt |
| `--help` | Show help message |

**Examples:**

```bash
./uninstall.sh                    # Full uninstall (interactive)
./uninstall.sh -y                 # Full uninstall (no confirmation)
./uninstall.sh --dotfiles-only    # Only remove dotfile symlinks
./uninstall.sh --keep-nix         # Remove dotfiles but keep Nix
```

### What it removes

1. Dotfile symlinks (unstow)
2. Stow (unless `--keep-stow`)
3. Home-manager/nix-darwin configuration
4. Nix and all packages (unless `--keep-nix`)
5. Nix cache files

**Warning**: Full uninstall is destructive and will remove all Nix-installed packages.

## Usage

After installation, use the `rebuild` command to apply configuration changes:

```bash
rebuild
```

This automatically detects your platform and runs the appropriate command:
- **macOS**: `darwin-rebuild switch --flake ~/.config/nix-darwin`
- **Linux**: `home-manager switch --flake ~/.config/nix-darwin`

## Structure

```
~/.dotfiles/
├── .config/
│   ├── nix-darwin/          # Nix configuration
│   │   ├── flake.nix        # Main flake (inputs & outputs)
│   │   ├── system/          # macOS system config (nix-darwin)
│   │   └── home/            # User config (home-manager)
│   │       ├── catppuccin.nix      # Global theme config
│   │       ├── programs/
│   │       │   ├── desktop/        # GNOME settings (Linux)
│   │       │   ├── terminal/       # ghostty, kitty, tmux, starship
│   │       │   ├── shell/          # zsh, fish
│   │       │   ├── git/            # git, lazygit, delta
│   │       │   └── utilities/      # bat, fzf, btop, k9s, etc.
│   │       └── development/        # Language toolchains
│   └── nvim/                # Neovim configuration
├── install.sh               # Installation script
├── uninstall.sh             # Uninstallation script
└── README.md
```

## Platform-specific features

### macOS
- Homebrew casks for GUI applications
- System preferences (Dock, Finder, keyboard)
- AeroSpace window manager

### Linux (Ubuntu/GNOME)
- GNOME settings via dconf (keyboard repeat, trackpad, dark mode)
- Dash-to-Dock extension with auto-hide
- GNOME Terminal with Catppuccin theme
- Window buttons on left (macOS-style)

## Customization

Key files to customize:

| Purpose | File |
|---------|------|
| Theme (flavor/accent) | `home/catppuccin.nix` |
| Shell aliases | `home/programs/shell/zsh.nix` |
| Git config | `home/programs/git/config.nix` |
| Neovim plugins | `.config/nvim/lua/plugins/` |
| Terminal settings | `home/programs/terminal/` |
| GNOME settings | `home/programs/desktop/gnome.nix` |

## License

[MIT LICENSE](./LICENSE)
