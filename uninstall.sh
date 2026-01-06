#!/usr/bin/env bash
set -e

######## COLORS ########
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)
######## END COLORS ########

function log {
    echo "${BLUE}${UNDERLINE}$1${RESET}"
}

function warn {
    echo "${YELLOW}$1${RESET}"
}

function error {
    echo "${RED}$1${RESET}"
}

function show_help {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dotfiles-only   Only unstow dotfiles, keep Nix and packages"
    echo "  --keep-nix        Keep Nix installed, remove dotfiles and config"
    echo "  --keep-stow       Keep stow installed"
    echo "  -y, --yes         Skip confirmation prompt"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full uninstall (interactive)"
    echo "  $0 -y                 # Full uninstall (no confirmation)"
    echo "  $0 --dotfiles-only    # Only remove dotfile symlinks"
    echo "  $0 --keep-nix         # Remove dotfiles but keep Nix"
}

# Parse arguments
DOTFILES_ONLY=false
KEEP_NIX=false
KEEP_STOW=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dotfiles-only)
            DOTFILES_ONLY=true
            shift
            ;;
        --keep-nix)
            KEEP_NIX=true
            shift
            ;;
        --keep-stow)
            KEEP_STOW=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "${YELLOW}
    .___      __    __  ___.__.__
  __| _/_____/  |__/ ____\__|  |   ____   ______
 / __ |/  _ \   __\   __\|  |  |  \_  __ \/  ___/
/ /_/ (  <_> )  |  |  |  |  |  |__ |  | \/\___ \\
\\____ |\\____/|__|  |__|  |__|____/ |__|  /____  >
     \\/                                       \\/
${RESET}"
echo "${RED}UNINSTALLER${RESET}"
echo ""

# Detect OS
OS="$(uname -s)"
log "Detected OS: $OS"

USER_HOME="$HOME"

# Show what will be removed based on flags
warn "This will remove:"
warn "  - Dotfile symlinks (unstow)"
if [[ "$DOTFILES_ONLY" == false ]]; then
    if [[ "$KEEP_STOW" == false ]]; then
        warn "  - Stow"
    fi
    if [[ "$KEEP_NIX" == false ]]; then
        warn "  - Home-manager/nix-darwin configuration"
        warn "  - All Nix-installed packages"
        warn "  - Nix itself"
    else
        warn "  - Home-manager/nix-darwin configuration"
    fi
fi
echo ""

# Confirm uninstall (unless -y flag)
if [[ "$SKIP_CONFIRM" == false ]]; then
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled."
        exit 0
    fi
fi

# Unstow dotfiles first (while stow is still available)
log "Unstowing dotfiles..."
cd "${USER_HOME}/.dotfiles"
stow -D . 2>/dev/null || true
log "Dotfiles unstowed"

# Exit early if --dotfiles-only
if [[ "$DOTFILES_ONLY" == true ]]; then
    log "Dotfiles-only mode complete!"
    exit 0
fi

# Remove stow (unless --keep-stow)
if [[ "$KEEP_STOW" == false ]]; then
    log "Removing stow..."
    if [[ "$OS" == "Darwin" ]]; then
        brew uninstall stow 2>/dev/null || true
    elif [[ "$OS" == "Linux" ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get remove -y stow
        elif command -v dnf &> /dev/null; then
            sudo dnf remove -y stow
        elif command -v pacman &> /dev/null; then
            sudo pacman -R --noconfirm stow
        elif command -v zypper &> /dev/null; then
            sudo zypper remove -y stow
        fi
    fi
    log "Stow removed"
else
    log "Keeping stow (--keep-stow flag)"
fi

# Remove home-manager/nix-darwin configuration
if [[ "$OS" == "Linux" ]]; then
    log "Removing home-manager configuration..."
    if command -v home-manager &> /dev/null; then
        home-manager uninstall 2>/dev/null || true
    fi
    rm -rf "${USER_HOME}/.local/state/home-manager" 2>/dev/null || true
    rm -rf "${USER_HOME}/.local/state/nix" 2>/dev/null || true
    rm -f "${USER_HOME}/.nix-profile" 2>/dev/null || true
    rm -rf "${USER_HOME}/.nix-defexpr" 2>/dev/null || true
    log "Home-manager removed"
elif [[ "$OS" == "Darwin" ]]; then
    log "Removing nix-darwin configuration..."
    if command -v darwin-rebuild &> /dev/null; then
        warn "Running darwin-rebuild to clean up..."
        # Note: Full nix-darwin removal requires manual steps
    fi
fi

# Uninstall Nix (unless --keep-nix)
if [[ "$KEEP_NIX" == false ]]; then
    log "Uninstalling Nix..."
    if [ -x /nix/nix-installer ]; then
        # Determinate Systems installer
        /nix/nix-installer uninstall --no-confirm
        log "Nix uninstalled via Determinate installer"
    else
        warn "Determinate installer not found, attempting manual cleanup..."

        # Stop nix-daemon
        if [[ "$OS" == "Linux" ]]; then
            sudo systemctl stop nix-daemon.service 2>/dev/null || true
            sudo systemctl disable nix-daemon.service 2>/dev/null || true
            sudo systemctl stop nix-daemon.socket 2>/dev/null || true
            sudo systemctl disable nix-daemon.socket 2>/dev/null || true
        elif [[ "$OS" == "Darwin" ]]; then
            sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
        fi

        # Remove nix files
        sudo rm -rf /nix 2>/dev/null || true
        sudo rm -rf /etc/nix 2>/dev/null || true
        sudo rm -f /etc/profile.d/nix.sh 2>/dev/null || true
        sudo rm -f /etc/bashrc.backup-before-nix 2>/dev/null || true
        sudo rm -f /etc/zshrc.backup-before-nix 2>/dev/null || true

        log "Nix manually removed"
    fi

    # Clean up remaining nix files in home
    log "Cleaning up remaining files..."
    rm -rf "${USER_HOME}/.cache/nix" 2>/dev/null || true
    rm -rf "${USER_HOME}/.local/share/nix" 2>/dev/null || true
else
    log "Keeping Nix (--keep-nix flag)"
fi

log "Uninstall complete!"
warn "Please restart your shell or log out/in for all changes to take effect."
