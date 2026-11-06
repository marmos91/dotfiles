#!/usr/bin/env bash
# Assert-based checks for install.sh, uninstall.sh and .stowrc.
# Every script run uses a throwaway HOME plus shims; the fake sudo never executes.
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAKE_HOME="$WORK/home"
SHIM_DIR="$WORK/shims"
mkdir -p "$FAKE_HOME/.nix-profile/bin" "$SHIM_DIR"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_HOME/.nix-profile/bin/zsh"
chmod +x "$FAKE_HOME/.nix-profile/bin/zsh"

SUDO_LOG="$WORK/sudo.log"
DARWIN_LOG="$WORK/darwin-rebuild.log"

PASSED=0
FAILED=0
RC=0
OUT=""

pass() { PASSED=$((PASSED + 1)); printf 'ok   %s\n' "$1"; }
fail() {
    FAILED=$((FAILED + 1))
    printf 'FAIL %s\n' "$1"
    printf '     rc=%s\n' "$RC"
    printf '%s\n' "$OUT" | sed 's/^/     | /'
}
contains() { case "$OUT" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
lacks() { case "$OUT" in *"$1"*) return 1 ;; *) return 0 ;; esac; }

reset() {
    : > "$SUDO_LOG"; : > "$DARWIN_LOG"
    FAKE_OS="Darwin"; FAKE_STOW_RC=0; FAKE_SUDO_FAIL=""
    FAKE_BREW_NO_STOW=""; OS_RELEASE_FILE=""; SYS_ROOT=""
    SUDO_USER=""; USER_OVERRIDE="$USER"; PATH_OVERRIDE=""
    rm -f "$SHIM_DIR/apt-get"
    OUT=""; RC=0
}

# Writes the os-release install.sh reads via DOTFILES_OS_RELEASE, so the Docker
# branch is chosen by the test, not by the host the suite happens to run on.
set_os_release() {
    OS_RELEASE_FILE="$WORK/os-release"
    printf 'ID=%s\nVERSION_CODENAME=%s\n' "$1" "$2" > "$OS_RELEASE_FILE"
}

######## SHIMS ########
shim() {
    cat > "$SHIM_DIR/$1"
    chmod +x "$SHIM_DIR/$1"
}

shim sudo <<'SHIM'
#!/usr/bin/env bash
# Records the command line; never executes it.
printf '%s\n' "$*" >> "$SUDO_LOG"
first=""
for arg in "$@"; do
    case "$arg" in
        -*) continue ;;
        *) first="$arg"; break ;;
    esac
done
if [[ "$first" == "tee" ]]; then
    cat >> "$SUDO_LOG"
fi
if [[ -n "${FAKE_SUDO_FAIL:-}" && "$first" == "$FAKE_SUDO_FAIL" ]]; then
    exit 1
fi
exit 0
SHIM

shim uname <<'SHIM'
#!/usr/bin/env bash
if [[ "${1:-}" == "-m" ]]; then
    echo x86_64
else
    echo "${FAKE_OS:-Darwin}"
fi
SHIM

shim stow <<'SHIM'
#!/usr/bin/env bash
exit "${FAKE_STOW_RC:-0}"
SHIM

shim curl <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM

# install.sh pins the 1Password apt key by fingerprint; answer with the pinned
# one so the Linux paths get past the check (curl downloads nothing here).
shim gpg <<'SHIM'
#!/usr/bin/env bash
if [[ " $* " == *" --show-keys "* ]]; then
    echo "pub:-:4096:1:AC2D62742012EA22:0:::-:::scESC::::::23::0:"
    echo "fpr:::::::::3FEF9748469ADBE15DA7CA80AC2D62742012EA22:"
fi
exit 0
SHIM

# curl downloads nothing here, so the pinned-hash check in fetch_and_verify
# would always fail; these tests cover the control flow, not the pins
# (tests/test-install-sh-helpers.sh covers those).
for sum in sha256sum shasum; do
    shim "$sum" <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM
done

shim nix <<'SHIM'
#!/usr/bin/env bash
echo "nix (Nix) 2.30.0"
SHIM

shim darwin-rebuild <<'SHIM'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DARWIN_LOG"
exit 0
SHIM

shim home-manager <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM

shim brew <<'SHIM'
#!/usr/bin/env bash
if [[ "${FAKE_BREW_NO_STOW:-}" == 1 && "$*" == "list --formula stow" ]]; then
    exit 1
fi
exit 0
SHIM

# Reached by the Linux install runs via set_default_shell; without it the host's
# real chsh prompts for a password.
shim chsh <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM

shim dpkg <<'SHIM'
#!/usr/bin/env bash
if [[ "${1:-}" == "--print-architecture" ]]; then
    echo x86_64
fi
exit 0
SHIM

# uninstall.sh runs the installer from $DOTFILES_SYS_ROOT, so T-10b can
# prove Nix removal is attempted without reaching the host's real /nix.
install_fake_nix_installer() {
    mkdir -p "$1/nix"
    cat > "$1/nix/nix-installer" <<SHIM
#!/usr/bin/env bash
printf 'nix-installer %s\n' "\$*" >> "$SUDO_LOG"
exit 0
SHIM
    chmod +x "$1/nix/nix-installer"
}

add_apt_get() {
    shim apt-get <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM
}
######## END SHIMS ########

run_script() {
    if [[ "$1" == install.sh ]]; then
        # install.sh refuses to switch without the sops age key.
        mkdir -p "$FAKE_HOME/.config/sops/age"
        : > "$FAKE_HOME/.config/sops/age/keys.txt"
        chmod 600 "$FAKE_HOME/.config/sops/age/keys.txt"
    fi
    local script="$1" dir="$2"
    shift 2
    set +e
    OUT="$(cd "$dir" && TERM=dumb HOME="$FAKE_HOME" PATH="${PATH_OVERRIDE:-$SHIM_DIR:$PATH}" \
        SUDO_USER="${SUDO_USER:-}" USER="${USER_OVERRIDE:-$USER}" \
        FAKE_OS="$FAKE_OS" FAKE_STOW_RC="$FAKE_STOW_RC" \
        FAKE_SUDO_FAIL="$FAKE_SUDO_FAIL" FAKE_BREW_NO_STOW="${FAKE_BREW_NO_STOW:-}" \
        DOTFILES_OS_RELEASE="${OS_RELEASE_FILE:-}" DOTFILES_SYS_ROOT="${SYS_ROOT:-}" \
        SUDO_LOG="$SUDO_LOG" DARWIN_LOG="$DARWIN_LOG" \
        bash "$REPO_ROOT/$script" "$@" 2>&1)"
    RC=$?
    set -e
}

# T-1: .stowrc is an allowlist, so anything outside .config stays put --
# including untracked scratch files a real checkout carries (git ls-files would
# miss those, so they are created explicitly below).
t1_stow_lints_only_the_intended_packages() {
    reset
    if ! command -v stow > /dev/null; then
        echo "skip stow_lints_only_the_intended_packages (stow not installed)"
        return
    fi
    local src="$WORK/src" linked expected
    mkdir -p "$src" "$FAKE_HOME"
    (cd "$REPO_ROOT" && git ls-files -z | tar -cf - --null -T -) | tar -xf - -C "$src"
    # One representative untracked scratch file: the allowlist ignores everything
    # outside .config, so any entry that leaks into $HOME fails the assertion.
    touch "$src/.envrc"
    set +e
    OUT="$(cd "$src" && HOME="$FAKE_HOME" stow -n -v1 . 2>&1)"
    RC=$?
    set -e
    linked="$(printf '%s\n' "$OUT" | sed -n 's/^LINK: \([^ ]*\) =>.*/\1/p' | sort | tr '\n' ' ')"
    expected=".config "
    if [[ "$RC" -ne 0 ]]; then
        fail "stow links only .config"
    elif [[ "$linked" == "$expected" ]]; then
        pass "stow links only .config"
    else
        OUT="linked:   $linked
expected: $expected"
        fail "stow links only .config"
    fi
}

# T-1b: the empty-home case above cannot catch a rule that folds .config instead
# of descending into it. A real $HOME already has .config, so the
# allowlist must still link their entries and stow must still exit 0.
t1b_stow_succeeds_against_a_populated_home() {
    reset
    if ! command -v stow > /dev/null; then
        echo "skip stow_succeeds_against_a_populated_home (stow not installed)"
        return
    fi
    local home="$WORK/populated" src="$WORK/populated-src" linked
    rm -rf "$home" "$src"
    # Unrelated real entries: what a lived-in machine has and the repo never ships.
    mkdir -p "$home/.config/htop" "$home/.gnupg" "$home/.local/bin"
    echo h > "$home/.config/htop/htoprc"
    echo t > "$home/.gnupg/trustdb.gpg"
    mkdir -p "$src"
    (cd "$REPO_ROOT" && git ls-files -z | tar -cf - --null -T -) | tar -xf - -C "$src"
    set +e
    OUT="$(cd "$src" && HOME="$home" stow -v1 . 2>&1)"
    RC=$?
    set -e
    linked="$(printf '%s\n' "$OUT" | sed -n 's/^LINK: \([^ ]*\) =>.*/\1/p' | sort | tr '\n' ' ')"
    if [[ "$RC" -eq 0 ]] && [[ "$linked" == *".config/nvim"* ]] \
        && [ -f "$home/.config/htop/htoprc" ]; then
        pass "stow succeeds and descends into a populated ~/.config"
    else
        OUT="linked: $linked"
        fail "stow succeeds and descends into a populated ~/.config"
    fi
}

# T-2: every hostname consumer (scutil, log line, flake ref) must agree.
t2_default_hostname_is_amaterasu() {
    reset
    run_script install.sh "$WORK/cwd"
    if [[ "$RC" -eq 0 ]] && grep -q 'scutil --set HostName amaterasu' "$SUDO_LOG" \
        && contains "Building nix-darwin configuration for 'amaterasu'" \
        && grep -q '#amaterasu' "$DARWIN_LOG"; then
        pass "default hostname is amaterasu everywhere"
    else
        OUT="$OUT
sudo.log:
$(cat "$SUDO_LOG")
darwin-rebuild.log:
$(cat "$DARWIN_LOG")"
        fail "default hostname is amaterasu everywhere"
    fi
}

# T-2c: the dropped flag must be rejected, not silently accepted.
t2c_hostname_flag_is_gone() {
    reset
    run_script install.sh "$WORK/cwd" --hostname foo
    if [[ "$RC" -eq 1 ]] && contains "Unknown option"; then
        pass "--hostname is rejected"
    else
        fail "--hostname is rejected"
    fi
}

# T-3: unsupported optional components are skips, not fatal. Fedora is chosen
# explicitly so a host apt-get cannot change the branch taken.
t3_unsupported_linux_setup_skips_instead_of_aborts() {
    reset
    FAKE_OS="Linux"
    add_apt_get
    set_os_release fedora 39
    if command -v dockerd > /dev/null; then
        echo "skip unsupported_linux_setup_skips_instead_of_aborts (dockerd present)"
        return
    fi
    run_script install.sh "$WORK/cwd"
    if [[ "$RC" -eq 0 ]] && contains "No Docker apt repository for 'fedora'" \
        && contains "Building home-manager configuration"; then
        pass "non-Debian Linux skips Docker and reaches home-manager"
    else
        fail "non-Debian Linux skips Docker and reaches home-manager"
    fi
}

# T-4: a real failure inside an optional installer must still abort.
t4_real_failure_inside_installer_still_aborts() {
    reset
    FAKE_OS="Linux"
    add_apt_get
    FAKE_SUDO_FAIL="apt-get"
    run_script install.sh "$WORK/cwd"
    if [[ "$RC" -ne 0 ]]; then
        pass "apt-get failure inside install_1password aborts the run"
    else
        fail "apt-get failure inside install_1password aborts the run"
    fi
}

# T-5: the Docker apt repo must match the distro. Match the deb line only --
# the GPG key line uses ${ID} too and would mask a hardcoded repo URL.
t5_docker_repo_url_matches_distro() {
    reset
    FAKE_OS="Linux"
    add_apt_get
    set_os_release debian bookworm
    if command -v dockerd > /dev/null; then
        echo "skip docker_repo_url_matches_distro (dockerd present)"
        return
    fi
    run_script install.sh "$WORK/cwd"
    if [[ "$RC" -eq 0 ]] && grep -q "deb \[.*download.docker.com/linux/debian " "$SUDO_LOG"; then
        pass "Docker repo URL uses /linux/debian"
    else
        OUT="$OUT
sudo.log:
$(cat "$SUDO_LOG")"
        fail "Docker repo URL uses /linux/debian"
    fi
}

# T-6: the docker group goes to the invoking user, never root.
t6_docker_group_targets_sudo_user() {
    reset
    FAKE_OS="Linux"
    add_apt_get
    set_os_release ubuntu noble
    if command -v dockerd > /dev/null; then
        echo "skip docker_group_targets_sudo_user (dockerd present)"
        return
    fi
    SUDO_USER=alice USER_OVERRIDE=root
    run_script install.sh "$WORK/cwd"
    if [[ "$RC" -eq 0 ]] && grep -q 'usermod -aG docker alice' "$SUDO_LOG" \
        && ! grep -q 'usermod -aG docker root' "$SUDO_LOG"; then
        pass "docker group granted to SUDO_USER, not root"
    else
        OUT="$OUT
sudo.log:
$(cat "$SUDO_LOG")"
        fail "docker group granted to SUDO_USER, not root"
    fi
}

# T-7: a failed unstow must abort before Nix is touched.
t7_unstow_failure_aborts_before_nix_removal() {
    reset
    FAKE_STOW_RC=1
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -ne 0 ]] && lacks "Dotfiles unstowed" && lacks "Uninstalling Nix"; then
        pass "failed unstow aborts before Nix removal"
    else
        fail "failed unstow aborts before Nix removal"
    fi

    reset
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && contains "Dotfiles unstowed"; then
        pass "successful unstow proceeds"
    else
        fail "successful unstow proceeds"
    fi

    # T-8: stow absent must not block the rest of the uninstall.
    reset
    PATH_NO_STOW="$WORK/nostow"
    mkdir -p "$PATH_NO_STOW"
    for f in "$SHIM_DIR"/*; do
        [[ "$(basename "$f")" == "stow" ]] || ln -sf "$f" "$PATH_NO_STOW/$(basename "$f")"
    done
    PATH_OVERRIDE="$PATH_NO_STOW:/usr/bin:/bin:/usr/sbin:/sbin"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && contains "stow is not installed" && contains "Keeping Nix"; then
        pass "missing stow is a warning, not a fatal abort"
    else
        fail "missing stow is a warning, not a fatal abort"
    fi

    # T-9: no brew keg for stow (home-manager owns it) must not abort.
    reset
    FAKE_BREW_NO_STOW=1
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && contains "not a Homebrew formula"; then
        pass "missing brew keg for stow does not abort"
    else
        fail "missing brew keg for stow does not abort"
    fi

    # T-10: on macOS, Nix must not be removed while nix-darwin is installed --
    # and the summary must say so before the user consents. Keyed on
    # /run/current-system, not a PATH lookup for darwin-rebuild.
    reset
    SYS_ROOT="$WORK/sysroot"
    mkdir -p "$SYS_ROOT/run/current-system"
    run_script uninstall.sh "$WORK/cwd" -y
    if [[ "$RC" -eq 0 ]] && contains "Nix itself (skipped: nix-darwin is still installed)" \
        && contains "Skipping Nix removal: nix-darwin is still installed" \
        && lacks "Uninstalling Nix" && lacks "All Nix-installed packages"; then
        pass "nix-darwin present: Nix removal is declined, not attempted"
    else
        fail "nix-darwin present: Nix removal is declined, not attempted"
    fi

    # T-10b: darwin-uninstaller removes /run/current-system but deliberately
    # leaves /nix/var/nix/profiles/system. That profile must not keep the guard
    # set, or the re-run loop the script and README promise never terminates.
    reset
    SYS_ROOT="$WORK/sysroot-profiles"
    mkdir -p "$SYS_ROOT/nix/var/nix/profiles/system-257-link"
    ln -s system-257-link "$SYS_ROOT/nix/var/nix/profiles/system"
    install_fake_nix_installer "$SYS_ROOT"
    run_script uninstall.sh "$WORK/cwd" -y
    if [[ "$RC" -eq 0 ]] && contains "Uninstalling Nix" && lacks "still installed" \
        && grep -q 'nix-installer uninstall --no-confirm' "$SUDO_LOG"; then
        pass "post-darwin-uninstaller: Nix removal proceeds"
    else
        OUT="$OUT
sudo.log:
$(cat "$SUDO_LOG")"
        fail "post-darwin-uninstaller: Nix removal proceeds"
    fi

    # T-12: entries the old .stowrc stowed but the allowlist now ignores must be
    # removed, not left dangling (repo file deleted) or live (still linking in).
    # Shapes match what stow really produces: a pre-existing ~/.local makes it
    # link file by file, and a dangling link's parent may be gone entirely.
    reset
    mkdir -p "$FAKE_HOME/.claude" "$FAKE_HOME/.local/bin"
    ln -sfn "$REPO_ROOT/CLAUDE.md" "$FAKE_HOME/CLAUDE.md"
    ln -sfn "$REPO_ROOT/.gitignore.global" "$FAKE_HOME/.gitignore.global"
    ln -sfn "$REPO_ROOT/.claude/settings.json" "$FAKE_HOME/.claude/settings.local.json"
    ln -sfn "$REPO_ROOT/.local/bin/gcal-personal-block" "$FAKE_HOME/.local/bin/gcal-personal-block"
    ln -sfn "$REPO_ROOT/removed-dir/gone.json" "$FAKE_HOME/.claude/orphan.json"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    # Tracked targets (settings.json, gcal-personal-block) must be copied, not
    # dropped; that the copy lands in ~/.local proves the sweep reaches it too.
    if [[ "$RC" -eq 0 ]] && [ ! -L "$FAKE_HOME/CLAUDE.md" ] \
        && [ ! -e "$FAKE_HOME/.gitignore.global" ] && [ ! -L "$FAKE_HOME/.gitignore.global" ] \
        && [ ! -L "$FAKE_HOME/.local/bin/gcal-personal-block" ] \
        && [ -f "$FAKE_HOME/.local/bin/gcal-personal-block" ] \
        && contains "Removed dangling link" \
        && [ ! -L "$FAKE_HOME/.claude/orphan.json" ] && [ ! -e "$FAKE_HOME/.claude/orphan.json" ] \
        && [ -f "$FAKE_HOME/.claude/settings.local.json" ] \
        && [ ! -L "$FAKE_HOME/.claude/settings.local.json" ]; then
        pass "stale links into the repo are cleaned up, ~/.local per-file links too"
    else
        fail "stale links into the repo are cleaned up, ~/.local per-file links too"
    fi

    # T-12a: a folded ~/.local must still be unfolded, not just left as a link.
    reset
    rm -rf "$FAKE_HOME/.local"
    ln -sfn "$REPO_ROOT/.config" "$FAKE_HOME/.local"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && [ ! -L "$FAKE_HOME/.local" ] && [ -d "$FAKE_HOME/.local/nvim" ]; then
        pass "folded ~/.local is unfolded"
    else
        fail "folded ~/.local is unfolded"
    fi

    # T-12e: a folded ~/.local whose repo dir is gone must be removed, not
    # abort the uninstall and leave a dangling ~/.local behind.
    reset
    rm -rf "$FAKE_HOME/.local"
    ln -sfn "$REPO_ROOT/.local-gone" "$FAKE_HOME/.local"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && [ ! -L "$FAKE_HOME/.local" ] \
        && contains "Removed dangling link $FAKE_HOME/.local"; then
        pass "dangling folded ~/.local is removed"
    else
        fail "dangling folded ~/.local is removed"
    fi

    # T-12d: a cyclic link in ~/.claude must not hang the resolver.
    reset
    mkdir -p "$FAKE_HOME/.claude"
    ln -sfn loop "$FAKE_HOME/.claude/loop"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && contains "Dotfiles unstowed"; then
        pass "a cyclic symlink does not hang the run"
    else
        fail "a cyclic symlink does not hang the run"
    fi

    # T-12b: a link whose repo file is gone must be dropped, and the message
    # must say so rather than claiming a replacement.
    reset
    mkdir -p "$FAKE_HOME/.claude"
    ln -sfn "$REPO_ROOT/.claude/does-not-exist.json" "$FAKE_HOME/.claude/gone.json"
    run_script uninstall.sh "$WORK/cwd" -y --keep-nix
    if [[ "$RC" -eq 0 ]] && [ ! -L "$FAKE_HOME/.claude/gone.json" ] \
        && [ ! -e "$FAKE_HOME/.claude/gone.json" ] \
        && contains "Removed dangling link" && lacks "Replaced stale link"; then
        pass "dangling link is removed and reported as such"
    else
        fail "dangling link is removed and reported as such"
    fi

    # T-12c: when the copy fails, the link must survive, nothing may claim it
    # was replaced, and the failure must be fatal (uninstall.sh must not remove
    # Nix while a live link into the repo remains).
    # chmod-based, so it cannot fail the way it tests as root.
    reset
    if [ "$(id -u)" -eq 0 ]; then
        echo "skip failed copy is reported (running as root)"
    else
        local cprepo="$WORK/cprepo" cphome="$WORK/cphome"
        rm -rf "$cprepo" "$cphome"
        mkdir -p "$cprepo/.claude" "$cphome/.claude" "$cprepo/scripts"
        cp "$REPO_ROOT/uninstall.sh" "$cprepo/"
        cp "$REPO_ROOT/scripts/stale-links.sh" "$cprepo/scripts/"
        echo x > "$cprepo/.claude/secret.json"
        ln -sfn "$cprepo/.claude/secret.json" "$cphome/.claude/settings.local.json"
        chmod 000 "$cprepo/.claude/secret.json"
        # Non-zero is the expected outcome here, so errexit must be off.
        set +e
        OUT="$(cd "$WORK/cwd" && TERM=dumb HOME="$cphome" PATH="$SHIM_DIR:$PATH" \
            DOTFILES_SYS_ROOT="" SUDO_LOG="$SUDO_LOG" DARWIN_LOG="$DARWIN_LOG" \
            bash "$cprepo/uninstall.sh" -y --keep-nix 2>&1)"; RC=$?
        set -e
        chmod 644 "$cprepo/.claude/secret.json"
        if [[ "$RC" -ne 0 ]] && lacks "Replaced stale link" && contains "Could not replace" \
            && [ -L "$cphome/.claude/settings.local.json" ]; then
            pass "failed copy is fatal, link left in place"
        else
            fail "failed copy is fatal, link left in place"
        fi
    fi

    # T-13: the folded shape must be unfolded without losing the user's own
    # state, which lives inside the repo while ~/.claude is a symlink to it.
    reset
    local foldrepo="$WORK/foldrepo" fold="$WORK/foldhome"
    rm -rf "$foldrepo" "$fold"
    mkdir -p "$foldrepo/.claude/projects/repo" "$fold" "$foldrepo/scripts"
    cp "$REPO_ROOT/uninstall.sh" "$foldrepo/"
    cp "$REPO_ROOT/scripts/stale-links.sh" "$foldrepo/scripts/"
    echo keep > "$foldrepo/.claude/projects/repo/state.json"
    ln -s "$foldrepo/.claude" "$fold/.claude"
    OUT="$(cd "$WORK/cwd" && TERM=dumb HOME="$fold" PATH="$SHIM_DIR:$PATH" \
        DOTFILES_SYS_ROOT="" SUDO_LOG="$SUDO_LOG" DARWIN_LOG="$DARWIN_LOG" \
        bash "$foldrepo/uninstall.sh" -y --keep-nix 2>&1)"; RC=$?
    if [[ "$RC" -eq 0 ]] && [ ! -L "$fold/.claude" ] \
        && [ "$(cat "$fold/.claude/projects/repo/state.json" 2>/dev/null)" == "keep" ]; then
        pass "folded ~/.claude is unfolded with user state intact"
    else
        fail "folded ~/.claude is unfolded with user state intact"
    fi
}

mkdir -p "$WORK/cwd"
t1_stow_lints_only_the_intended_packages
t1b_stow_succeeds_against_a_populated_home
t2_default_hostname_is_amaterasu
t2c_hostname_flag_is_gone
t3_unsupported_linux_setup_skips_instead_of_aborts
t4_real_failure_inside_installer_still_aborts
t5_docker_repo_url_matches_distro
t6_docker_group_targets_sudo_user
t7_unstow_failure_aborts_before_nix_removal

printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]]
