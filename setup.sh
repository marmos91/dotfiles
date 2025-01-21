#!/usr/bin/env bash

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
    .___      __    _____.__.__                 
  __| _/_____/  |__/ ____\__|  |   ____   ______
 / __ |/  _ \   __\   __\|  |  | _/ __ \ /  ___/
/ /_/ (  <_> )  |  |  |  |  |  |_\  ___/ \___ \ 
\____ |\____/|__|  |__|  |__|____/\___  >____  >
     \/                               \/     \/ 
"

HOSTNAME="amaterasu"

# Setting hostname and computer name
log "Setting hostname and computer name to $HOSTNAME"
sudo scutil --set HostName $HOSTNAME
sudo scutil --set ComputerName $HOSTNAME
sudo scutil --set LocalHostName $HOSTNAME

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    log "Nix is not installed. Installing it now..."
    sh <(curl -L https://nixos.org/nix/install)
else
    log "Nix is already installed with version $(nix --version)"
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log "Homebrew is not installed. Installing it now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log "Homebrew is already installed with version $(brew --version | head -n 1)"
fi

nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ./.config/nix-darwin#amaterasu

stow .
