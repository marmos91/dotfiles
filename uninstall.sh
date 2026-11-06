#!/usr/bin/env bash
set -e

######## COLORS ########
RED=$(tput setaf 1 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
BLUE=$(tput setaf 4 2>/dev/null || true)
UNDERLINE=$(tput smul 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)
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
    echo "  --keep-1password  Keep 1Password installed (Linux only)"
    echo "  --keep-docker     Keep Docker installed (Linux only)"
    echo "  --purge-data      Also delete Docker volumes and the Nix store (off by default)"
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
KEEP_1PASSWORD=false
KEEP_DOCKER=false
PURGE_DATA=false
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
        --keep-1password)
            KEEP_1PASSWORD=true
            shift
            ;;
        --keep-docker)
            KEEP_DOCKER=true
            shift
            ;;
        --purge-data)
            PURGE_DATA=true
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

# nix-darwin owns /nix on macOS and nix-installer refuses to uninstall under it.
# Keyed on /run/current-system: darwin-uninstaller removes that but deliberately
# leaves /nix/var/nix/profiles/system behind, so the profile cannot be the test
# (it would block Nix removal forever). SYS_ROOT is a test seam.
NIX_DARWIN_PRESENT=false
sys_root="${DOTFILES_SYS_ROOT:-}"
if [[ "$OS" == "Darwin" && -e "${sys_root}/run/current-system" ]]; then
    NIX_DARWIN_PRESENT=true
fi

USER_HOME="$HOME"

# Show what will be removed based on flags
warn "This will remove:"
warn "  - Dotfile symlinks (unstow)"
if [[ "$DOTFILES_ONLY" == false ]]; then
    if [[ "$KEEP_STOW" == false ]]; then
        warn "  - Stow"
    fi
    warn "  - Home-manager configuration (Linux; nix-darwin is left installed on macOS)"
    if [[ "$KEEP_NIX" == false ]]; then
        if [[ "$NIX_DARWIN_PRESENT" == true ]]; then
            warn "  - Nix itself (skipped: nix-darwin is still installed)"
        else
            warn "  - All Nix-installed packages"
            warn "  - Nix itself"
            # The Determinate installer removes /nix on its own; only the manual
            # fallback is gated, so say so here rather than promise otherwise.
            if [[ "$PURGE_DATA" == true ]]; then
                warn "  - The Nix store at /nix (permanent)"
            else
                warn "  - The Nix store at /nix is removed by the Determinate installer;"
                warn "    the manual fallback keeps it unless --purge-data is given"
            fi
        fi
    fi
    if [[ "$OS" == "Linux" && "$KEEP_1PASSWORD" == false ]]; then
        warn "  - 1Password app and CLI"
    fi
    if [[ "$OS" == "Linux" && "$KEEP_DOCKER" == false ]]; then
        warn "  - Docker Engine"
        if [[ "$PURGE_DATA" == true ]]; then
            warn "  - Docker data: /var/lib/docker and /var/lib/containerd"
            warn "    (every image, container and named volume - unrecoverable)"
        else
            warn "  - Docker data is KEPT (pass --purge-data to delete it)"
        fi
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

# -P so the physical path is used even when the repo is reached through a symlink.
DOTFILES_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Shared with install.sh so the two cannot drift. Uninstall keeps a failed
# cleanup fatal: leaving a live link into a repo that is about to be removed is
# worse than aborting.
# shellcheck source=scripts/stale-links.sh disable=SC1091
. "$DOTFILES_DIR/scripts/stale-links.sh"
stale_msg() { warn "$1"; }

# Unstow dotfiles first (while stow is still available)
log "Unstowing dotfiles..."
cd "$DOTFILES_DIR"
unlink_stale_dotfiles_links
if ! command -v stow &> /dev/null; then
    warn "stow is not installed; skipping unstow"
else
    stow -D .
    log "Dotfiles unstowed"
fi

# Exit early if --dotfiles-only
if [[ "$DOTFILES_ONLY" == true ]]; then
    log "Dotfiles-only mode complete!"
    exit 0
fi

# Remove stow (unless --keep-stow)
if [[ "$KEEP_STOW" == false ]]; then
    log "Removing stow..."
    if [[ "$OS" == "Darwin" ]]; then
        # stow usually comes from home-manager here, so a missing brew keg is not an error
        if brew list --formula stow > /dev/null 2>&1; then
            brew uninstall stow
        else
            warn "stow is not a Homebrew formula (nix provides it); remove it with home-manager"
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get remove -y stow
        elif command -v dnf &> /dev/null; then
            sudo dnf remove -y stow
        elif command -v pacman &> /dev/null; then
            sudo pacman -R --noconfirm stow
        elif command -v zypper &> /dev/null; then
            sudo zypper remove -y stow
        else
            warn "No supported package manager found; remove stow manually"
        fi
    else
        warn "Unsupported OS: $OS; remove stow manually"
    fi
else
    log "Keeping stow (--keep-stow flag)"
fi

# Remove 1Password (Linux only, unless --keep-1password)
if [[ "$OS" == "Linux" && "$KEEP_1PASSWORD" == false ]]; then
    ARCH="$(uname -m)"

    if command -v 1password &> /dev/null || [[ -f /opt/1Password/1password ]] || command -v op &> /dev/null; then
        log "Removing 1Password..."

        if [[ "$ARCH" == "x86_64" ]]; then
            # x86_64: Remove via apt
            if command -v apt-get &> /dev/null; then
                sudo apt-get remove -y 1password 1password-cli 2>/dev/null || true
                sudo apt-get autoremove -y 2>/dev/null || true

                # Remove apt repository
                sudo rm -f /etc/apt/sources.list.d/1password.list 2>/dev/null || true

                # Remove GPG keys
                sudo rm -f /usr/share/keyrings/1password-archive-keyring.gpg 2>/dev/null || true

                # Remove debsig policy
                sudo rm -rf /etc/debsig/policies/AC2D62742012EA22 2>/dev/null || true
                sudo rm -rf /usr/share/debsig/keyrings/AC2D62742012EA22 2>/dev/null || true
            fi
        elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            # ARM64: Manual removal
            # Remove 1Password app
            if [[ -d /opt/1Password ]]; then
                log "Removing 1Password app from /opt..."
                sudo rm -rf /opt/1Password
            fi

            # Remove desktop file
            sudo rm -f /usr/share/applications/1password.desktop 2>/dev/null || true

            # Remove CLI
            if [[ -f /usr/local/bin/op ]]; then
                log "Removing 1Password CLI..."
                sudo rm -f /usr/local/bin/op
            fi

            # Remove onepassword-cli group
            if getent group onepassword-cli > /dev/null 2>&1; then
                log "Removing onepassword-cli group..."
                sudo groupdel onepassword-cli 2>/dev/null || true
            fi

            # Remove system integration files created by after-install.sh
            sudo rm -f /usr/share/polkit-1/actions/com.1password.1Password.policy 2>/dev/null || true
            sudo rm -f /etc/chromium/native-messaging-hosts/com.1password.1password.json 2>/dev/null || true
            sudo rm -f /etc/opt/chrome/native-messaging-hosts/com.1password.1password.json 2>/dev/null || true
            # Only 1Password's own policy files, then the directory only if it is
            # empty — these roots are shared and may hold other policies.
            sudo rm -f /etc/chromium/policies/managed/com.1password*.json 2>/dev/null || true
            sudo rm -f /etc/opt/chrome/policies/managed/com.1password*.json 2>/dev/null || true
            sudo rmdir --ignore-fail-on-non-empty /etc/chromium/policies/managed /etc/opt/chrome/policies/managed 2>/dev/null || true
        fi

        # Clean up user data (optional - keep by default for safety)
        # rm -rf "${USER_HOME}/.config/1Password" 2>/dev/null || true
        # rm -rf "${USER_HOME}/.1password" 2>/dev/null || true

        log "1Password removed"
    else
        log "1Password not found, skipping"
    fi
elif [[ "$OS" == "Linux" && "$KEEP_1PASSWORD" == true ]]; then
    log "Keeping 1Password (--keep-1password flag)"
fi

# Remove Docker (Linux only, unless --keep-docker)
if [[ "$OS" == "Linux" && "$KEEP_DOCKER" == false ]]; then
    if command -v dockerd &> /dev/null; then
        log "Removing Docker..."

        # Stop Docker service
        sudo systemctl stop docker.service 2>/dev/null || true
        sudo systemctl stop docker.socket 2>/dev/null || true
        sudo systemctl stop containerd.service 2>/dev/null || true

        # Remove Docker packages
        if command -v apt-get &> /dev/null; then
            sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
            sudo apt-get autoremove -y 2>/dev/null || true

            # Remove Docker repository
            sudo rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
            sudo rm -f /etc/apt/keyrings/docker.asc 2>/dev/null || true
        fi

        # Remove Docker data (images, containers, volumes) — opt-in only.
        if [[ "$PURGE_DATA" == true ]]; then
            warn "Deleting Docker data permanently: /var/lib/docker /var/lib/containerd"
            sudo rm -rf /var/lib/docker 2>/dev/null || true
            sudo rm -rf /var/lib/containerd 2>/dev/null || true
        else
            warn "Docker data kept at /var/lib/docker and /var/lib/containerd (pass --purge-data to remove)"
        fi

        # Remove Docker group
        if getent group docker > /dev/null 2>&1; then
            sudo groupdel docker 2>/dev/null || true
        fi

        log "Docker removed"
    else
        log "Docker not found, skipping"
    fi
elif [[ "$OS" == "Linux" && "$KEEP_DOCKER" == true ]]; then
    log "Keeping Docker (--keep-docker flag)"
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
elif [[ "$OS" == "Darwin" && "$NIX_DARWIN_PRESENT" == true ]]; then
    warn "nix-darwin configuration left installed; remove it with:"
    warn "  sudo /run/current-system/sw/bin/darwin-uninstaller"
    warn "Then re-run this script to remove Nix."
fi

# Uninstall Nix (unless --keep-nix)
if [[ "$KEEP_NIX" == false && "$NIX_DARWIN_PRESENT" == false ]]; then
    log "Uninstalling Nix..."
    # SYS_ROOT seam: the test suite must not reach the host's real installer.
    nix_installer="${sys_root}/nix/nix-installer"
    if [ -x "$nix_installer" ]; then
        # Determinate Systems installer
        "$nix_installer" uninstall --no-confirm
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

        # Remove nix files. /nix holds the store — opt-in only here; the
        # Determinate installer branch above always removes it.
        if [[ "$PURGE_DATA" == true ]]; then
            warn "Deleting the Nix store permanently: /nix"
            sudo rm -rf /nix 2>/dev/null || true
        else
            warn "Nix store kept at /nix (pass --purge-data to remove it)"
        fi
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
elif [[ "$KEEP_NIX" == false ]]; then
    # nix-installer refuses to uninstall while nix-darwin is installed
    warn "Skipping Nix removal: nix-darwin is still installed."
else
    log "Keeping Nix (--keep-nix flag)"
fi

log "Uninstall complete!"
warn "Please restart your shell or log out/in for all changes to take effect."
