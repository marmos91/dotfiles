#!/usr/bin/env bash
set -e

# -P so the physical path is used even when the repo is reached through a symlink.
DOTFILES_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$DOTFILES_DIR"

# Shared with uninstall.sh so the two cannot drift.
# shellcheck source=scripts/common.sh disable=SC1091
. "$DOTFILES_DIR/scripts/common.sh"
# shellcheck source=scripts/stale-links.sh disable=SC1091
. "$DOTFILES_DIR/scripts/stale-links.sh"
stale_msg() { log "$1"; }

# Download one artifact and fail closed unless its SHA-256 matches. TLS alone is
# not a trust anchor for anything this script later runs as root. Portable
# across macOS (shasum) and Linux (sha256sum). Never calls sudo.
function fetch_and_verify {
	local url="$1" dest="$2" sha256="$3"

	if ! curl -fsSLo "$dest" "$url"; then
		echo "Error: download failed: $url" >&2
		exit 1
	fi
	if ! printf '%s  %s\n' "$sha256" "$dest" | (sha256sum -c - 2>/dev/null || shasum -a 256 -c -) >/dev/null; then
		echo "Error: checksum mismatch for $url (expected sha256 $sha256)" >&2
		exit 1
	fi
}

# Fail closed unless the key file holds exactly one primary key and that key
# is this fingerprint. A bare `grep -q "^fpr:..."` would also pass a bundle that
# merely *contains* the trusted key, and `--dearmor` installs the whole bundle
# as a trust anchor — so an attacker who controls the download could append
# their own key and sign packages for the pinned repo.
function verify_gpg_fingerprint {
	local keyfile="$1" fingerprint="$2" keys

	keys="$(gpg --show-keys --with-colons --fingerprint "$keyfile" 2>/dev/null || true)"
	if [ "$(printf '%s\n' "$keys" | grep -c '^pub:')" != 1 ] \
		|| [ "$(printf '%s\n' "$keys" | awk -F: '/^fpr:/{print $10; exit}')" != "$fingerprint" ]; then
		echo "Error: GPG key fingerprint mismatch in $keyfile (expected $fingerprint)" >&2
		exit 1
	fi
}

# One exit trap for every temp dir the script creates: separate `trap ... EXIT`
# assignments would overwrite each other and leak downloaded key material.
TEMP_DIRS=()
trap 'rm -rf "${TEMP_DIRS[@]}" 2>/dev/null || true' EXIT

# Pinned upstream data. Bump a version and its hash together; a changed
# artifact then fails loudly instead of running.
ONEPASSWORD_GPG_FINGERPRINT="3FEF9748469ADBE15DA7CA80AC2D62742012EA22"
ONEPASSWORD_DEBSIG_POL_SHA256="c0c148807d8dc588750a9cc512c7243ed10a9cfd5519a5a6f0a038ad66a19c39"
ONEPASSWORD_APP_VERSION="8.12.44"
ONEPASSWORD_APP_SHA256="50146bb14bc010e8442cb69c172ef8ff2501c07829fb18254188e7173eb9cd74"
ONEPASSWORD_CLI_VERSION="2.32.0"
ONEPASSWORD_CLI_SHA256="6f3d571aabe7701e21ad4b0f9d30207c3dcabdb2f9c261e3651106dde0ee8946"

# `nix run` without a rev resolves through the flake registry
# (`github:LnL7/nix-darwin`, `github:nix-community/home-manager`), which tracks
# HEAD — and on macOS it runs as root. Pin the revs flake.lock already locks, so
# the bootstrap runs the same code the switch then builds. Bump these whenever
# `nix flake update` moves them.
NIX_DARWIN_REV="4cff07de74b50e64bdd68cd4e722ab5b6b35ee48"
HOME_MANAGER_REV="d85475546a5f6696233bba981933e2227a584047"

function show_help {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --shell <shell>   Set default shell (zsh or bash). Default: zsh"
    echo "  --shell-only      Only change the default shell, skip installation"
    echo "  --no-stow         Skip stowing dotfiles"
    echo "  --skip-nix        Skip Nix installation (use existing Nix)"
    echo "  --no-1password    Skip 1Password installation (Linux only)"
    echo "  --no-docker       Skip Docker installation (Linux only)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full install with defaults"
    echo "  $0 --shell bash             # Install with bash as default shell"
    echo "  $0 --shell-only             # Only set zsh as default shell"
    echo "  $0 --no-1password           # Skip 1Password installation on Linux"
}

# Parse arguments
DEFAULT_SHELL="zsh"
SHELL_ONLY=false
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

warn "
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

# Flake identity: mirrors `hostname` and `username` in .config/nix-darwin/flake.nix.
# The flake defines outputs for these names only, so they are not host-derived.
DOTFILES_HOSTNAME=amaterasu
DOTFILES_USERNAME=marmos91

# Setting hostname (macOS only)
if [[ "$OS" == "Darwin" ]]; then
    log "Setting hostname and computer name to $DOTFILES_HOSTNAME"
    sudo scutil --set HostName "$DOTFILES_HOSTNAME"
    sudo scutil --set ComputerName "$DOTFILES_HOSTNAME"
    sudo scutil --set LocalHostName "$DOTFILES_HOSTNAME"
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
            # Homebrew's installer tracks its `HEAD` branch and publishes no
            # checksum, so there is nothing to verify it against. Refuse rather
            # than pipe a moving branch into bash — but do not abort the whole
            # install, or a fresh Mac could never reach the pinned Nix step.
            # The caller prints the one actionable message.
            return 1
        else
            log "Homebrew is already installed with version $(brew --version | head -n 1)"
        fi
        # The caller tests this function's status, which turns off errexit for
        # its whole body, so every install step must propagate failure itself.
        brew install stow || return 1
    elif [[ "$OS" == "Linux" ]]; then
        # Linux: detect package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y stow || return 1
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y stow || return 1
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm stow || return 1
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y stow || return 1
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
    if install_stow; then
        # A pre-existing ~/.claude must not abort the install, so a failed unfold is
        # only a warning; stow still runs.
        unlink_stale_dotfiles_links || log "Warning: some stale links could not be cleaned up"

        # Stow dotfiles
        log "Stowing dotfiles..."
        stow .
    else
        log "Skipping stow: stow could not be installed. Install it with your package manager (macOS: 'brew install stow', Homebrew from https://brew.sh), then run 'stow .' from ~/.dotfiles."
    fi
else
    log "Skipping stow (--no-stow flag)"
fi

# Install Nix using Determinate Systems installer (cross-platform)
if [[ "$SKIP_NIX" == true ]]; then
    log "Skipping Nix installation (--skip-nix flag)"
else
    log "Installing Nix with Determinate Systems installer..."
    if ! command -v nix &> /dev/null; then
        # The install.determinate.systems/nix endpoint tracks the latest release
        # and publishes no per-version checksum, so this pins the GitHub release
        # binary instead: the asset with a published, verifiable hash.
        NIX_INSTALLER_VERSION="v3.24.2"
        case "$OS:$ARCH" in
            Darwin:arm64)
                NIX_INSTALLER_TARGET="aarch64-darwin"
                NIX_INSTALLER_SHA256="0163fb800be1749880fb51cd529a88fd4dace474601a144d0db9929006eba775"
                ;;
            Linux:aarch64 | Linux:arm64)
                NIX_INSTALLER_TARGET="aarch64-linux"
                NIX_INSTALLER_SHA256="bc18d8d8ca12f95d219b5978201e15d0049b2e9d8b7c49593f26503c87172145"
                ;;
            Linux:x86_64)
                NIX_INSTALLER_TARGET="x86_64-linux"
                NIX_INSTALLER_SHA256="22ed14ee1b24d100d388f1fc245e3062bd5982433d159cffa6dec34c0eb15dab"
                ;;
            *)
                # Determinate stopped publishing an Intel macOS build, so there
                # is no pinned asset to verify for this target.
                log "Error: no pinned nix-installer for $OS:$ARCH. Install Nix manually from https://determinate.systems, then re-run with --skip-nix."
                exit 1
                ;;
        esac

        NIX_INSTALLER_DIR=$(mktemp -d)
        TEMP_DIRS+=("$NIX_INSTALLER_DIR")
        fetch_and_verify \
            "https://github.com/DeterminateSystems/nix-installer/releases/download/${NIX_INSTALLER_VERSION}/nix-installer-${NIX_INSTALLER_TARGET}" \
            "${NIX_INSTALLER_DIR}/nix-installer" \
            "$NIX_INSTALLER_SHA256"
        chmod +x "${NIX_INSTALLER_DIR}/nix-installer"
        "${NIX_INSTALLER_DIR}/nix-installer" install --no-confirm

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
    # Temp dirs are still removed by the EXIT trap via TEMP_DIRS.
    local ONEPASSWORD_KEY_DIR ONEPASSWORD_ASC ONEPASSWORD_POL ONEPASSWORD_APP_DIR ONEPASSWORD_TARBALL ONEPASSWORD_CLI_DIR

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
        # x86_64: Use apt repository.
        if ! command -v apt-get &> /dev/null; then
            log "Warning: 1Password apt installation requires apt-get"
            return 0
        fi

        #
        # The apt key and the debsig policy are the trust anchors for every
        # later `apt-get install 1password`, so both are pinned: the key by
        # fingerprint, the policy by hash. The key is also key material, so it
        # lives in a private temp dir that is removed on exit.
        ONEPASSWORD_KEY_DIR=$(mktemp -d)
        TEMP_DIRS+=("$ONEPASSWORD_KEY_DIR")
        ONEPASSWORD_ASC="${ONEPASSWORD_KEY_DIR}/1password.asc"

        if ! curl -fsSLo "$ONEPASSWORD_ASC" https://downloads.1password.com/linux/keys/1password.asc; then
            log "Error: could not download the 1Password archive key"
            exit 1
        fi
        verify_gpg_fingerprint "$ONEPASSWORD_ASC" "$ONEPASSWORD_GPG_FINGERPRINT"

        # Add 1Password repository key (--yes to overwrite if exists)
        sudo gpg --yes --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg "$ONEPASSWORD_ASC"

        # Add 1Password repository
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null

        # Add debsig policy for package verification, hash-checked before it is
        # written: it names the key that signs the packages.
        ONEPASSWORD_POL="${ONEPASSWORD_KEY_DIR}/1password.pol"
        fetch_and_verify \
            https://downloads.1password.com/linux/debian/debsig/1password.pol \
            "$ONEPASSWORD_POL" \
            "$ONEPASSWORD_DEBSIG_POL_SHA256"
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        sudo install -m 644 -o root -g root -- "$ONEPASSWORD_POL" /etc/debsig/policies/AC2D62742012EA22/1password.pol
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        sudo gpg --yes --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg "$ONEPASSWORD_ASC"

        # Install 1Password
        sudo apt-get update && sudo apt-get install -y 1password 1password-cli
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        # ARM64: Use tar.gz installation
        if [[ "$app_installed" == false ]]; then
            log "Installing 1Password app for ARM64 via tar.gz..."

            ONEPASSWORD_APP_DIR=$(mktemp -d)
            TEMP_DIRS+=("$ONEPASSWORD_APP_DIR")
            ONEPASSWORD_TARBALL="${ONEPASSWORD_APP_DIR}/1password.tar.gz"

            # A versioned URL, not `1password-latest.tar.gz`: the hash pin below
            # is only meaningful for one exact build.
            fetch_and_verify \
                "https://downloads.1password.com/linux/tar/stable/aarch64/1password-${ONEPASSWORD_APP_VERSION}.arm64.tar.gz" \
                "$ONEPASSWORD_TARBALL" \
                "$ONEPASSWORD_APP_SHA256"

            # Extract unprivileged: the archive is untrusted until verified, and
            # root's tar can write anywhere on disk.
            tar --no-same-owner --no-same-permissions -C "$ONEPASSWORD_APP_DIR" -xf "$ONEPASSWORD_TARBALL"

            # Install to /opt
            sudo mkdir -p /opt/1Password
            sudo mv "$ONEPASSWORD_APP_DIR"/1password-*/* /opt/1Password
            # The extract was unprivileged, so `mv` preserved the invoking user's
            # ownership. Restore root ownership and directory modes before
            # running the installer, or after-install.sh would be a
            # user-writable script executed via sudo.
            sudo chown -R root:root /opt/1Password
            # The extract also inherited the caller's umask, so a hardened umask
            # (027/077) leaves root-owned 0700 binaries the user cannot run.
            # u=rwX keeps execute bits and adds read for group/other.
            sudo chmod -R u=rwX,go=rX /opt/1Password

            # Run post-install script
            sudo /opt/1Password/after-install.sh
        fi

        # Install 1Password CLI separately for ARM64
        if [[ "$cli_installed" == false ]]; then
            log "Installing 1Password CLI for ARM64..."
            ONEPASSWORD_CLI_DIR=$(mktemp -d)
            TEMP_DIRS+=("$ONEPASSWORD_CLI_DIR")

            fetch_and_verify \
                "https://cache.agilebits.com/dist/1P/op2/pkg/v${ONEPASSWORD_CLI_VERSION}/op_linux_arm64_v${ONEPASSWORD_CLI_VERSION}.zip" \
                "${ONEPASSWORD_CLI_DIR}/op.zip" \
                "$ONEPASSWORD_CLI_SHA256"
            unzip -q "${ONEPASSWORD_CLI_DIR}/op.zip" -d "$ONEPASSWORD_CLI_DIR"
            sudo mv "${ONEPASSWORD_CLI_DIR}/op" /usr/local/bin/

            # Create onepassword-cli group and set permissions for CLI integration
            sudo groupadd -f onepassword-cli
            sudo chown root:onepassword-cli /usr/local/bin/op
            sudo chmod g+s /usr/local/bin/op
        fi

        # Patch desktop file for Wayland support and disable GPU (ARM64 compatibility)
        if [[ -f /usr/share/applications/1password.desktop ]]; then
            log "Patching 1Password desktop file for Wayland..."
            sudo sed -i 's|Exec=/opt/1Password/1password|Exec=/opt/1Password/1password --ozone-platform=wayland --disable-gpu|' /usr/share/applications/1password.desktop
        fi
    else
        log "Warning: Unsupported architecture for 1Password: $ARCH"
        return 0
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
        return 0
    fi

    # distro id and codename drive the Docker apt repository URL;
    # DOTFILES_OS_RELEASE is a test seam so the branch is not host-derived
    local os_release="${DOTFILES_OS_RELEASE:-/etc/os-release}" target_user
    # shellcheck disable=SC1090
    if [[ -r "$os_release" ]]; then . "$os_release"; fi
    case "$ID" in
        ubuntu|debian) ;;
        *)
            log "Warning: No Docker apt repository for '${ID:-unknown}'; skipping Docker"
            return 0
            ;;
    esac

    log "Installing Docker Engine..."

    # Install dependencies
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl

    # Add Docker's official GPG key
    #
    # Not fingerprint-pinned: this is out of scope for the 1Password/Nix/Homebrew
    # pinning work and is tracked as follow-up debt. It is the same trust-anchor
    # shape as the 1Password apt key above, so `verify_gpg_fingerprint` applies.
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    target_user="${SUDO_USER:-$USER}"
    sudo usermod -aG docker "$target_user"

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    log "Docker installed successfully"
    log "Note: Log out and back in for docker group membership to take effect"
}

install_docker

# Initialize Nix configuration
log "Initializing Nix configuration..."
if ! command -v nix &> /dev/null; then
    log "Warning: Nix is not available. Skipping Nix configuration."
else
    USER_HOME="$HOME"

    # The nix-darwin/home-manager config refuses to activate without the age
    # key (home/secrets/default.nix), so a fresh machine would fail at the last
    # step with a half-applied switch. This script cannot create the key — it
    # only exists once, and it is the one thing that cannot be regenerated — so
    # stop here with the instruction instead. `age-keygen` itself only arrives
    # with the first switch, hence `nix shell` (nix is present: this block is
    # guarded by `command -v nix`).
    if [[ ! -r "$HOME/.config/sops/age/keys.txt" ]]; then
        log "Missing sops age key: $HOME/.config/sops/age/keys.txt"
        log "Create it first (see .config/nix-darwin/home/secrets/README.md, section 1):"
        log "  mkdir -p ~/.config/sops/age"
        log "  nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt"
        log "Store a copy in 1Password, then re-run this script (or run 'rebuild')."
        exit 1
    fi

    if [[ "$OS" == "Darwin" ]]; then
        # macOS: use nix-darwin
        log "Building nix-darwin configuration for '$DOTFILES_HOSTNAME'..."
        log "This requires administrator privileges..."

        if ! command -v darwin-rebuild &> /dev/null; then
            sudo -H nix --extra-experimental-features 'nix-command flakes' run "github:LnL7/nix-darwin/${NIX_DARWIN_REV}" -- switch --flake "${DOTFILES_DIR}/.config/nix-darwin#${DOTFILES_HOSTNAME}"
        else
            darwin-rebuild switch --flake "${DOTFILES_DIR}/.config/nix-darwin#${DOTFILES_HOSTNAME}"
        fi

        log "nix-darwin configuration activated successfully"
    elif [[ "$OS" == "Linux" ]]; then
        # Linux: use standalone home-manager
        # Determine the correct configuration based on architecture
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            HM_CONFIG="${DOTFILES_USERNAME}-aarch64"
        else
            HM_CONFIG="${DOTFILES_USERNAME}"
        fi
        log "Building home-manager configuration for '$HM_CONFIG'..."

        # Install home-manager if not available
        if ! command -v home-manager &> /dev/null; then
            log "Installing home-manager..."
            nix run "github:nix-community/home-manager/${HOME_MANAGER_REV}" -- switch --flake "${DOTFILES_DIR}/.config/nix-darwin#${HM_CONFIG}"
        else
            home-manager switch --flake "${DOTFILES_DIR}/.config/nix-darwin#${HM_CONFIG}"
        fi

        log "home-manager configuration activated successfully"

        # Set default shell on Linux
        set_default_shell "$DEFAULT_SHELL" "$USER_HOME"
    fi

    log "Note: You may need to restart your shell for all changes to take effect"
fi
