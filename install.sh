#!/usr/bin/env bash
set -e

######## COLORS ########
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)
######## END COLORS ########

function log {
	echo "${BLUE}${UNDERLINE}$1${RESET}"
}

function titlize {
	echo "${YELLOW}$1${RESET}"
}

function show_help {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --shell <shell>   Set default shell (zsh or bash). Default: zsh"
    echo "  --shell-only      Only change the default shell, skip installation"
    echo "  --hostname <name> Set hostname (macOS only). Default: amaterasu"
    echo "  --no-stow         Skip stowing dotfiles"
    echo "  --skip-nix        Skip Nix installation (use existing Nix)"
    echo "  --no-1password    Skip 1Password installation (Linux only)"
    echo "  --no-docker       Skip Docker installation (Linux only)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full install with defaults"
    echo "  $0 --shell bash             # Install with bash as default shell"
    echo "  $0 --hostname myhost        # Install with custom hostname (macOS)"
    echo "  $0 --shell-only             # Only set zsh as default shell"
    echo "  $0 --no-1password           # Skip 1Password installation on Linux"
}

# Parse arguments
DEFAULT_SHELL="zsh"
SHELL_ONLY=false
CUSTOM_HOSTNAME=""
NO_STOW=false
SKIP_NIX=false
SKIP_1PASSWORD=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --shell)
            DEFAULT_SHELL="$2"
            shift 2
            ;;
        --shell-only)
            SHELL_ONLY=true
            shift
            ;;
        --hostname)
            CUSTOM_HOSTNAME="$2"
            shift 2
            ;;
        --no-stow)
            NO_STOW=true
            shift
            ;;
        --skip-nix)
            SKIP_NIX=true
            shift
            ;;
        --no-1password)
            SKIP_1PASSWORD=true
            shift
            ;;
        --no-docker)
            SKIP_DOCKER=true
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

# Validate shell choice
if [[ "$DEFAULT_SHELL" != "zsh" && "$DEFAULT_SHELL" != "bash" ]]; then
    echo "Error: Invalid shell '$DEFAULT_SHELL'. Must be 'zsh' or 'bash'."
    exit 1
fi

# Function to set default shell
set_default_shell() {
    local shell_name="$1"
    local user_home="$2"
    local shell_path="${user_home}/.nix-profile/bin/${shell_name}"

    if [[ -x "$shell_path" ]]; then
        log "Setting ${shell_name} as default shell..."
        # Add nix shell to /etc/shells if not present
        if ! grep -q "$shell_path" /etc/shells; then
            echo "$shell_path" | sudo tee -a /etc/shells > /dev/null
            log "Added $shell_path to /etc/shells"
        fi
        # Change default shell
        if [[ "$SHELL" != "$shell_path" ]]; then
            chsh -s "$shell_path"
            log "Default shell changed to ${shell_name}"
        else
            log "${shell_name} is already the default shell"
        fi
    else
        log "Error: ${shell_path} not found. Make sure nix packages are installed."
        return 1
    fi
}

# Handle --shell-only flag
if [[ "$SHELL_ONLY" == true ]]; then
    log "Shell-only mode: skipping installation"
    log "Default shell: $DEFAULT_SHELL"
    set_default_shell "$DEFAULT_SHELL" "$HOME"
    log "Done! Please log out and back in for changes to take effect."
    exit 0
fi

titlize "
    .___      __    __  ___.__.__
  __| _/_____/  |__/ ____\__|  |   ____   ______
 / __ |/  _ \   __\   __\|  |  |  \_  __ \/  ___/
/ /_/ (  <_> )  |  |  |  |  |  |__ |  | \/\___ \\
\\____ |\\____/|__|  |__|  |__|____/ |__|  /____  >
     \\/                                       \\/
"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
log "Detected OS: $OS ($ARCH)"
log "Default shell: $DEFAULT_SHELL"

# Configuration - use flag, env var, or default
if [[ -n "$CUSTOM_HOSTNAME" ]]; then
    HOSTNAME="$CUSTOM_HOSTNAME"
else
    HOSTNAME="${HOSTNAME:-amaterasu}"
fi

# Setting hostname (macOS only)
if [[ "$OS" == "Darwin" ]]; then
    log "Setting hostname and computer name to $HOSTNAME"
    sudo scutil --set HostName "$HOSTNAME"
    sudo scutil --set ComputerName "$HOSTNAME"
    sudo scutil --set LocalHostName "$HOSTNAME"
fi

# Install stow
install_stow() {
    if command -v stow &> /dev/null; then
        log "Stow is already installed"
        return 0
    fi

    log "Installing stow..."
    if [[ "$OS" == "Darwin" ]]; then
        # macOS: use Homebrew
        if ! command -v brew &> /dev/null; then
            log "Homebrew is not installed. Installing it now..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for current session
            if [[ -f /opt/homebrew/bin/brew ]]; then
                export PATH="/opt/homebrew/bin:$PATH"
            elif [[ -f /usr/local/bin/brew ]]; then
                export PATH="/usr/local/bin:$PATH"
            fi
        else
            log "Homebrew is already installed with version $(brew --version | head -n 1)"
        fi
        brew install stow
    elif [[ "$OS" == "Linux" ]]; then
        # Linux: detect package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y stow
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y stow
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm stow
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y stow
        else
            log "Error: Could not detect package manager. Please install stow manually."
            exit 1
        fi
    else
        log "Error: Unsupported OS: $OS"
        exit 1
    fi
    log "Stow installed successfully"
}

# Install and run stow (unless --no-stow)
if [[ "$NO_STOW" == false ]]; then
    install_stow

    # Stow dotfiles
    log "Stowing dotfiles..."
    stow .
else
    log "Skipping stow (--no-stow flag)"
fi

# Install Nix using Determinate Systems installer (cross-platform)
if [[ "$SKIP_NIX" == true ]]; then
    log "Skipping Nix installation (--skip-nix flag)"
else
    log "Installing Nix with Determinate Systems installer..."
    if ! command -v nix &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

        # Source nix for current session
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        log "Nix installed successfully"
    else
        log "Nix is already installed with version $(nix --version)"
    fi
fi

# Install 1Password on Linux (for SSH agent and commit signing)
install_1password() {
    if [[ "$OS" != "Linux" ]]; then
        return 0
    fi

    if [[ "$SKIP_1PASSWORD" == true ]]; then
        log "Skipping 1Password installation (--no-1password flag)"
        return 0
    fi

    # Install dependencies for 1Password (Electron app)
    log "Installing 1Password dependencies..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq \
            libglib2.0-0 libgtk-3-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
            libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
            libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libasound2t64 \
            libsecret-1-0 libnotify4 2>/dev/null || \
        sudo apt-get install -y -qq \
            libglib2.0-0 libgtk-3-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
            libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
            libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libasound2 \
            libsecret-1-0 libnotify4 2>/dev/null || true
    fi

    local app_installed=false
    local cli_installed=false

    if command -v 1password &> /dev/null || [[ -f /opt/1Password/1password ]]; then
        log "1Password app is already installed"
        app_installed=true
    fi

    if command -v op &> /dev/null; then
        log "1Password CLI is already installed"
        cli_installed=true
    fi

    if [[ "$app_installed" == true && "$cli_installed" == true ]]; then
        return 0
    fi

    if [[ "$ARCH" == "x86_64" ]]; then
        # x86_64: Use apt repository
        # Add 1Password GPG key (--yes to overwrite if exists)
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

        # Add 1Password repository
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null

        # Add debsig policy for package verification
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol > /dev/null
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --yes --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

        # Install 1Password
        sudo apt-get update && sudo apt-get install -y 1password 1password-cli
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        # ARM64: Use tar.gz installation
        if [[ "$app_installed" == false ]]; then
            log "Installing 1Password app for ARM64 via tar.gz..."

            # Create temp directory
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"

            # Download and extract
            curl -sSO https://downloads.1password.com/linux/tar/stable/aarch64/1password-latest.tar.gz
            sudo tar -xf 1password-latest.tar.gz

            # Install to /opt
            sudo mkdir -p /opt/1Password
            sudo mv 1password-*/* /opt/1Password

            # Run post-install script
            sudo /opt/1Password/after-install.sh

            # Cleanup
            cd -
            rm -rf "$TEMP_DIR"
        fi

        # Install 1Password CLI separately for ARM64
        if [[ "$cli_installed" == false ]]; then
            log "Installing 1Password CLI for ARM64..."
            TEMP_DIR_CLI=$(mktemp -d)
            cd "$TEMP_DIR_CLI"
            curl -sSO https://cache.agilebits.com/dist/1P/op2/pkg/v2.32.0/op_linux_arm64_v2.32.0.zip
            unzip -q op_linux_arm64_v2.32.0.zip
            sudo mv op /usr/local/bin/

            # Create onepassword-cli group and set permissions for CLI integration
            sudo groupadd -f onepassword-cli
            sudo chown root:onepassword-cli /usr/local/bin/op
            sudo chmod g+s /usr/local/bin/op

            cd -
            rm -rf "$TEMP_DIR_CLI"
        fi

        # Patch desktop file for Wayland support and disable GPU (ARM64 compatibility)
        if [[ -f /usr/share/applications/1password.desktop ]]; then
            log "Patching 1Password desktop file for Wayland..."
            sudo sed -i 's|Exec=/opt/1Password/1password|Exec=/opt/1Password/1password --ozone-platform=wayland --disable-gpu|' /usr/share/applications/1password.desktop
        fi
    else
        log "Warning: Unsupported architecture for 1Password: $ARCH"
        return 1
    fi

    log "1Password installed successfully"
    log "Note: Open 1Password and enable SSH Agent in Settings → Developer"
}

install_1password

# Install Docker on Linux
install_docker() {
    if [[ "$OS" != "Linux" ]]; then
        return 0
    fi

    if [[ "$SKIP_DOCKER" == true ]]; then
        log "Skipping Docker installation (--no-docker flag)"
        return 0
    fi

    if command -v dockerd &> /dev/null; then
        log "Docker is already installed"
        return 0
    fi

    if ! command -v apt-get &> /dev/null; then
        log "Warning: Docker installation only supported on Debian/Ubuntu"
        return 1
    fi

    log "Installing Docker Engine..."

    # Install dependencies
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker "$USER"

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    log "Docker installed successfully"
    log "Note: Log out and back in for docker group membership to take effect"
}

install_docker

# Initialize Nix configuration
log "Initializing Nix configuration..."
if command -v nix &> /dev/null; then
    USER_HOME="$HOME"
    USERNAME="$(whoami)"

    if [[ "$OS" == "Darwin" ]]; then
        # macOS: use nix-darwin
        log "Building nix-darwin configuration for '$HOSTNAME'..."
        log "This requires administrator privileges..."

        if ! command -v darwin-rebuild &> /dev/null; then
            sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "${USER_HOME}/.config/nix-darwin#${HOSTNAME}"
        else
            darwin-rebuild switch --flake "${USER_HOME}/.config/nix-darwin#${HOSTNAME}"
        fi

        log "nix-darwin configuration activated successfully"
    elif [[ "$OS" == "Linux" ]]; then
        # Linux: use standalone home-manager
        # Determine the correct configuration based on architecture
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            HM_CONFIG="${USERNAME}-aarch64"
        else
            HM_CONFIG="${USERNAME}"
        fi
        log "Building home-manager configuration for '$HM_CONFIG'..."

        # Install home-manager if not available
        if ! command -v home-manager &> /dev/null; then
            log "Installing home-manager..."
            nix run home-manager -- switch --flake "${USER_HOME}/.config/nix-darwin#${HM_CONFIG}"
        else
            home-manager switch --flake "${USER_HOME}/.config/nix-darwin#${HM_CONFIG}"
        fi

        log "home-manager configuration activated successfully"

        # Set default shell on Linux
        set_default_shell "$DEFAULT_SHELL" "$USER_HOME"
    fi

    log "Note: You may need to restart your shell for all changes to take effect"
else
    log "Warning: Nix is not available. Skipping Nix configuration."
fi
