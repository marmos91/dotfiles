# shellcheck shell=bash
# Shared by install.sh and uninstall.sh.
#
# $HOME entries an older .stowrc stowed into this repo. The allowlist in .stowrc
# can no longer unlink them, so they would survive as live or dangling symlinks.
#
# The caller provides $HOME, $DOTFILES_DIR and stale_msg().
# Returns non-zero when a fold or a replace could not be done: install.sh treats
# that as a warning, uninstall.sh as fatal.

# readlink -f is GNU-only, so resolve symlinks by hand (dangling links included).
# Physical paths only: callers compare the result against $DOTFILES_DIR.
# Non-zero means the path could not be resolved at all (a cycle); a link whose
# parent directory is gone still prints a path, so callers can match it and
# remove it instead of silently skipping it.
resolve_path() {
    local p="$1" n dir tail i=0
    while [ -L "$p" ]; do
        # A cyclic link would spin forever.
        if [ "$i" -ge 40 ]; then
            echo "Could not resolve $1: too many symlink hops" >&2
            return 1
        fi
        i=$((i + 1))
        n="$(readlink "$p")"
        [[ "$n" == /* ]] || n="$(dirname "$p")/$n"
        p="$n"
    done
    # The parent of a dangling link can be gone: resolve the nearest existing
    # ancestor physically and keep the missing tail as is.
    tail="$(basename "$p")"
    dir="$(dirname "$p")"
    while ! [ -d "$dir" ]; do
        tail="$(basename "$dir")/$tail"
        dir="$(dirname "$dir")"
    done
    printf '%s/%s\n' "$(cd "$dir" && pwd -P)" "$tail"
}

unlink_stale_dotfiles_links() {
    local entry path target tmp failed=0
    # A folded ~/.claude or ~/.local is a link to this repo, so it also holds the
    # user's own state (projects, ~/.local/share, ...). Copy it out first; the repo
    # copy stays intact if the copy fails. Staged beside $entry, so the swap is a
    # rename, not a cross-device copy that can fail half-done.
    for entry in "$HOME/.claude" "$HOME/.local"; do
        [ -L "$entry" ] || continue
        target="$(resolve_path "$entry")" || continue
        case "$target" in
            "$DOTFILES_DIR"/*) ;;
            *) continue ;;
        esac
        # Dangling (the repo dir is gone): nothing to copy, and leaving the link
        # would break every tool that writes under it.
        if [ ! -e "$target" ]; then
            rm -f "$entry" && stale_msg "Removed dangling link $entry"
            continue
        fi
        tmp="$entry.new"
        rm -rf "$tmp"
        if cp -a "$target" "$tmp" && rm -f "$entry" && mv "$tmp" "$entry"; then
            stale_msg "Unfolded $entry into a real directory"
        elif [ -e "$entry" ] || [ -L "$entry" ]; then
            # The link is still there, so the copy is redundant.
            rm -rf "$tmp"
            echo "Could not unfold $entry; move it out of the repo by hand" >&2
            failed=1
        else
            # The link is gone, so $tmp holds the only copy of the user's data.
            echo "Could not unfold $entry; its contents are in $tmp" >&2
            failed=1
        fi
    done
    # .gitignore.global is listed because the repo file is gone, so the link a
    # user still has is dangling.
    for entry in "$HOME/CLAUDE.md" "$HOME/.pi" "$HOME/.gitignore.global"; do
        if [ -L "$entry" ]; then
            target="$(resolve_path "$entry")" || continue
            case "$target" in
                "$DOTFILES_DIR"/*) rm -f "$entry" && stale_msg "Removed stale link $entry" ;;
            esac
        fi
    done
    # A pre-existing ~/.claude or ~/.local makes stow link file by file instead of
    # folding the directory, so those links sit inside a real dir. Process
    # substitution, not a pipe: a pipeline subshell would swallow $failed.
    for entry in "$HOME/.claude" "$HOME/.local"; do
        # Not -L: a folded link is the unfold loop's job. find reports its start
        # point, so a link here would be "replaced" a second time as $entry.tmp.
        [ -d "$entry" ] && [ ! -L "$entry" ] || continue
        while read -r path; do
            target="$(resolve_path "$path")" || continue
            case "$target" in
                "$DOTFILES_DIR"/*)
                    if [ -e "$target" ]; then
                        rm -rf "$path.tmp"
                        if cp -a "$target" "$path.tmp" && rm -f "$path" && mv "$path.tmp" "$path"; then
                            stale_msg "Replaced stale link $path"
                        else
                            rm -f "$path.tmp"
                            echo "Could not replace $path; move it out of the repo by hand" >&2
                            failed=1
                        fi
                    else
                        rm -f "$path" && stale_msg "Removed dangling link $path"
                    fi
                    ;;
            esac
        done < <(find "$entry" -type l 2>/dev/null)
    done
    return "$failed"
}
