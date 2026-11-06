#!/usr/bin/env bash
# Self-check for the Homebrew trust-seeding activation fragment.
#
# Renders the exact fragment with `nix eval`, asserts it drops to the user
# before writing, then runs it against a throwaway HOME with `sudo` stubbed.
# Touches nothing outside a temp dir; no root.
#
# Run on macOS from the repo root: bash tests/test-homebrewtrust-guard.sh
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

# Only the trust fragment; the Homebrew Bundle part needs a real brew.
SCRIPT="$(cd "$REPO_ROOT" && nix eval --raw \
	".config/nix-darwin#darwinConfigurations.amaterasu.config.system.activationScripts.homebrew.text" 2>/dev/null \
	| sed '/^# Homebrew Bundle/,$d')"
[ -n "$SCRIPT" ] || fail "could not render the homebrew activation script (needs nix)"

# T-A1: every write happens under `sudo --user=`, never as root.
printf '%s\n' "$SCRIPT" | grep -q '^sudo --user=[^ ]* --set-home /bin/sh -c' \
	|| fail "T-A1: trust seeding does not drop to the user"
echo "ok: T-A1 seeding runs as the user"

# T-A2: the fragment writes the flake's tap list. The stub stands in for
# `sudo --user=x --set-home`: it drops those flags and points HOME at $WORK.
mkdir -p "$WORK/bin" "$WORK/home"
cat > "$WORK/bin/sudo" <<STUB
#!/usr/bin/env bash
shift 2
HOME="$WORK/home" exec "\$@"
STUB
chmod +x "$WORK/bin/sudo"
PATH="$WORK/bin:$PATH" bash -c "$SCRIPT" || fail "T-A2: fragment failed"
grep -q '"trustedtaps":\["cubbit/tap"' "$WORK/home/.homebrew/trust.json" \
	|| fail "T-A2: trust.json does not hold the tap list"
echo "ok: T-A2 trust.json written with the tap list"
