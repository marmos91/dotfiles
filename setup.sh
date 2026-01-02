#!/usr/bin/env bash
set -e

function log {
	echo "${BLUE}${UNDERLINE}$1${RESET}"
}
function titlize {
	echo "${YELLOW}$1${RESET}"
}
######## COLORS ########
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)
RESET=$(tput sgr0)
######## END COLORS ########
titlize "
    .___      __    __  ___.__.__                 
  __| _/_____/  |__/ ____\__|  |   ____   ______
 / __ |/  _ \   __\   __\|  |  |  \_  __ \/  ___/
/ /_/ (  <_> )  |  |  |  |  |  |__ |  | \/\___ \ 
\____ |\____/|__|  |__|  |__|____/ |__|   /____  >
     \/                                        \/ 
"
# Configuration - change this for a different machine
HOSTNAME="${HOSTNAME:-amaterasu}"
# Setting hostname and computer name
log "Setting hostname and computer name to $HOSTNAME"
sudo scutil --set HostName "$HOSTNAME"
sudo scutil --set ComputerName "$HOSTNAME"
sudo scutil --set LocalHostName "$HOSTNAME"

# Check if Homebrew is installed
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

# Install stow with brew
log "Installing stow with Homebrew..."
if ! command -v stow &> /dev/null; then
    brew install stow
    log "Stow installed successfully"
else
    log "Stow is already installed"
fi

# Install Nix using Determinate Systems installer for macOS
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
# Stow dotfiles
log "Stowing dotfiles..."
stow .
# Initialize nix-darwin flake
log "Initializing nix-darwin configuration..."
if command -v nix &> /dev/null; then
    # Build and activate the nix-darwin configuration
    log "Building nix-darwin configuration for 'amaterasu'..."
    log "This requires administrator privileges..."
    
    # Store the current user's home
    USER_HOME="$HOME"
    
    # First time setup - use nix run
    if ! command -v darwin-rebuild &> /dev/null; then
        sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ${USER_HOME}/.config/nix-darwin#amaterasu
    else
        # Subsequent runs can use darwin-rebuild directly
        darwin-rebuild switch --flake ${USER_HOME}/.config/nix-darwin#amaterasu
    fi
    
    log "nix-darwin configuration activated successfully"
    log "Note: You may need to restart your shell for all changes to take effect"
else
    log "Warning: Nix is not available. Skipping nix-darwin initialization."
fi
