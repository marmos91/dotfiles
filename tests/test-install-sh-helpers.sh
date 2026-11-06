#!/usr/bin/env bash
# Self-checks for install.sh's fetch/verify helpers.
#
# The helper bodies are extracted from install.sh by their `function name {`
# header and sourced in a subshell, so the test exercises the shipped code
# rather than a copy. `curl` is stubbed on PATH; no network, no root.
#
# Run from the repo root: bash tests/test-install-sh-helpers.sh
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
	echo "FAIL: $1" >&2
	exit 1
}

pass() {
	echo "ok: $1"
}

extract_function() {
	sed -n "/^function $1 {/,/^}/p" "$INSTALL_SH"
}

# A stub curl that copies a fixture to the -o destination, or fails outright.
# Deliberately not `curl -f` semantics: the point is to prove the helper's own
# error handling, not the stub's.
make_stub_curl() {
	local stub_dir="$1" fixture="$2" exit_code="$3"
	mkdir -p "$stub_dir"
	# install.sh always calls `curl -fsSLo <dest> <url>`.
	cat > "${stub_dir}/curl" <<STUB
#!/usr/bin/env bash
dest="\$2"
if [ "${exit_code}" -ne 0 ]; then
	exit ${exit_code}
fi
cp "${fixture}" "\$dest"
exit 0
STUB
	chmod +x "${stub_dir}/curl"
}

# Run one install.sh helper, extracted verbatim, in a subshell.
run_helper() {
	local fn="$1"
	shift
	( set -e; eval "$(extract_function "$fn")"; "$fn" "$@" ) >/dev/null 2>&1
}

run_fetch_and_verify() { PATH="$1:$PATH" run_helper fetch_and_verify "${@:2}"; }

GOOD_FIXTURE="${WORK}/good.bin"
printf 'verified artifact\n' > "$GOOD_FIXTURE"
GOOD_SHA="$(shasum -a 256 "$GOOD_FIXTURE" | awk '{print $1}')"
BAD_SHA="0000000000000000000000000000000000000000000000000000000000000000"

# T-B1 — a delivered file whose hash does not match aborts.
STUB="${WORK}/stub-bad"
make_stub_curl "$STUB" "$GOOD_FIXTURE" 0
if run_fetch_and_verify "$STUB" "https://example.invalid/a" "${WORK}/bad.out" "$BAD_SHA"; then
	fail "T-B1: fetch_and_verify accepted a checksum mismatch"
fi
pass "T-B1 checksum mismatch aborts"

# T-B2 — a good hash succeeds and leaves the content; a failing download aborts
# before any checksum step (the old `-sSO`-without-`-f` regression).
STUB="${WORK}/stub-good"
make_stub_curl "$STUB" "$GOOD_FIXTURE" 0
if ! run_fetch_and_verify "$STUB" "https://example.invalid/a" "${WORK}/good.out" "$GOOD_SHA"; then
	fail "T-B2: fetch_and_verify rejected a matching checksum"
fi
cmp -s "$GOOD_FIXTURE" "${WORK}/good.out" || fail "T-B2: destination content differs from the fixture"

STUB="${WORK}/stub-fail"
make_stub_curl "$STUB" "$GOOD_FIXTURE" 22
if run_fetch_and_verify "$STUB" "https://example.invalid/a" "${WORK}/fail.out" "$GOOD_SHA"; then
	fail "T-B2: fetch_and_verify accepted a failed download"
fi
[ ! -e "${WORK}/fail.out" ] || fail "T-B2: destination exists after a failed download"
pass "T-B2 good hash succeeds, failed download aborts"

# T-C — verify_gpg_fingerprint accepts its own key and rejects a mutated one.
# The accept case proves it reads exactly one primary key's first fpr.
if ! command -v gpg >/dev/null 2>&1; then
	fail "T-C: gpg is required for the fingerprint checks"
fi

GNUPGHOME="${WORK}/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME
gpg --batch --quiet --passphrase '' --quick-gen-key \
	"Test Key <test@example.invalid>" default default never >/dev/null 2>&1 \
	|| fail "T-C: could not generate a throwaway key"

KEYFILE="${WORK}/test.asc"
gpg --batch --quiet --armor --export test@example.invalid > "$KEYFILE" 2>/dev/null \
	|| fail "T-C: could not export the throwaway key"

GOOD_FPR="$(gpg --show-keys --with-colons --fingerprint "$KEYFILE" 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')"
[ -n "$GOOD_FPR" ] || fail "T-C: could not read the generated fingerprint"
MUTATED_FPR="0000000000000000000000000000000000000000"

run_verify_fingerprint() { run_helper verify_gpg_fingerprint "$@"; }

run_verify_fingerprint "$KEYFILE" "$GOOD_FPR" || fail "T-C: rejected the key's own fingerprint"
if run_verify_fingerprint "$KEYFILE" "$MUTATED_FPR"; then
	fail "T-C: accepted a mismatched fingerprint"
fi

# T-C2 — a bundle that contains the trusted key *plus* a foreign one must be
# rejected. Presence-only matching would accept this, and `--dearmor` would
# install both keys as trust anchors.
gpg --batch --quiet --passphrase '' --quick-gen-key \
	"Foreign Key <foreign@example.invalid>" default default never >/dev/null 2>&1 \
	|| fail "T-C2: could not generate a second throwaway key"
cat "$KEYFILE" > "${WORK}/combined.asc"
gpg --batch --quiet --armor --export foreign@example.invalid >> "${WORK}/combined.asc" 2>/dev/null \
	|| fail "T-C2: could not export the foreign key"
[ "$(gpg --show-keys --with-colons --fingerprint "${WORK}/combined.asc" 2>/dev/null | grep -c '^pub:')" = 2 ] \
	|| fail "T-C2: fixture does not hold two keys"
if run_verify_fingerprint "${WORK}/combined.asc" "$GOOD_FPR"; then
	fail "T-C2: accepted a bundle with an appended foreign key"
fi
pass "T-C fingerprint match accepted, mismatch and appended key abort"

echo "all install.sh helper checks passed"
