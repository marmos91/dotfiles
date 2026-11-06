#!/bin/sh
# Exercises the shipped `secrets edit` helper (a writeShellScriptBin in
# home/packages.nix, shared by zsh and bash) against a throwaway sops store. The
# helper is built from the flake and invoked directly, so this tests what ships.
#
# Regression targets: `sops -e` on a /tmp path matched no creation rule and the
# exit status was ignored, so the unconditional `mv` replaced the encrypted
# store with plaintext; a crashing editor left an empty scratch file that was
# written into the store; and the store lost its 0600 mode.
set -u

fail() { echo "FAIL: $*" >&2; exit 1; }

for tool in nix sops jq age-keygen; do
  command -v "$tool" >/dev/null || { echo "skip: $tool not found"; exit 77; }
done

repo=$(cd "$(dirname "$0")/../.config/nix-darwin" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Build the helper exactly as home-manager will install it.
nix build --no-link --print-out-paths --out-link "$tmp/helper" \
  --impure --expr '
    let
      cfg = (builtins.getFlake "'"$repo"'").darwinConfigurations.amaterasu.config.home-manager.users.marmos91;
    in builtins.head (builtins.filter (p: (p.name or "") == "secrets") cfg.home.packages)' \
  >/dev/null 2>&1 || fail "could not build the secrets helper"
helper="$(readlink -f "$tmp/helper")/bin/secrets"
[ -x "$helper" ] || fail "helper not at $helper"

# Editor stub: replaces the scratch file's contents with a known value.
cat > "$tmp/editor" <<'EOF'
#!/bin/sh
printf 'edited-by-test\n' > "$1"
EOF
chmod +x "$tmp/editor"

SOPS_AGE_KEY_FILE="$tmp/age.txt" age-keygen -o "$tmp/age.txt" 2>/dev/null ||
  fail "age-keygen failed"
pub=$(grep -o 'age1[a-z0-9]*' "$tmp/age.txt" | head -1)
[ -n "$pub" ] || fail "could not read the age recipient"

fx="$tmp/xdg/nix-darwin/home/secrets"

# $1 = sops recipient for .sops.yaml
make_fixture() {
  rm -rf "$tmp/xdg" "$tmp/tmpdir"
  mkdir -p "$fx" "$tmp/tmpdir" "$tmp/stage"
  cat > "$fx/.sops.yaml" <<EOF
keys:
  - &p $1
creation_rules:
  - path_regex: secrets\\.yaml\$
    key_groups:
      - age:
          - *p
EOF
  printf 'mysecret: hello\nother: keep\n' > "$tmp/stage/secrets.yaml"
  sops --config "$fx/.sops.yaml" -e "$tmp/stage/secrets.yaml" > "$fx/secrets.yaml" ||
    fail "fixture encryption failed"
  chmod 600 "$fx/secrets.yaml"
}

run_secrets() {
  XDG_CONFIG_HOME="$tmp/xdg" TMPDIR="$tmp/tmpdir" EDITOR="${TEST_EDITOR:-$tmp/editor}" \
    SOPS_AGE_KEY_FILE="$tmp/age.txt" \
    "$helper" edit mysecret >"$tmp/out" 2>&1
}

# (a) round trip: the store stays encrypted and carries the edit
make_fixture "$pub"
run_secrets || fail "(a) secrets edit exited non-zero: $(cat "$tmp/out")"
SOPS_AGE_KEY_FILE="$tmp/age.txt" sops -d "$fx/secrets.yaml" > "$tmp/dec" 2>/dev/null ||
  fail "(a) secrets.yaml is no longer decryptable — the store was replaced by plaintext"
grep -q '^mysecret: edited-by-test$' "$tmp/dec" ||
  fail "(a) edit did not reach the store: $(cat "$tmp/dec")"
grep -q '^other: keep$' "$tmp/dec" || fail "(a) unrelated secret lost"
# The store holds every secret; a rewrite must not widen its mode.
[ -n "$(find "$fx/secrets.yaml" -perm 600)" ] ||
  fail "(a) secrets.yaml lost its 0600 mode"

# (b) temp files (including the plaintext copy) are removed on the happy path
[ -z "$(ls -A "$tmp/tmpdir")" ] ||
  fail "(b) temp files left behind: $(ls -A "$tmp/tmpdir")"

# (c) a failing editor must leave the store byte-identical. The stub truncates
# the scratch file and exits non-zero, which the old code wrote back as "".
make_fixture "$pub"
cp "$fx/secrets.yaml" "$tmp/before"
cat > "$tmp/bad-editor" <<'EOF'
#!/bin/sh
: > "$1"
exit 1
EOF
chmod +x "$tmp/bad-editor"
TEST_EDITOR="$tmp/bad-editor" run_secrets
rc=$?
[ "$rc" -ne 0 ] || fail "(c) editor failure was not reported (exit 0)"
grep -q 'editor failed' "$tmp/out" ||
  fail "(c) reported the wrong failure: $(cat "$tmp/out")"
cmp -s "$tmp/before" "$fx/secrets.yaml" ||
  fail "(c) secrets.yaml was modified despite the editor failure"
[ -z "$(ls -A "$tmp/tmpdir")" ] ||
  fail "(c) temp files left behind: $(ls -A "$tmp/tmpdir")"

# (d) an editor that empties the file and exits 0 is still refused: an empty
# scratch file means the editor never showed the value, not that it is "".
make_fixture "$pub"
cp "$fx/secrets.yaml" "$tmp/before"
cat > "$tmp/empty-editor" <<'EOF'
#!/bin/sh
: > "$1"
EOF
chmod +x "$tmp/empty-editor"
TEST_EDITOR="$tmp/empty-editor" run_secrets
rc=$?
[ "$rc" -ne 0 ] || fail "(d) empty value was accepted (exit 0)"
grep -q 'empty value' "$tmp/out" ||
  fail "(d) reported the wrong failure: $(cat "$tmp/out")"
cmp -s "$tmp/before" "$fx/secrets.yaml" ||
  fail "(d) secrets.yaml was modified despite the empty value"

# (e) a failed decrypt must leave the store untouched and the edit unapplied.
make_fixture "$pub"
cp "$fx/secrets.yaml" "$tmp/before"
mkdir -p "$tmp/bin"
cat > "$tmp/bin/sops" <<EOF
#!/bin/sh
case "\$*" in
  *--extract*) exec $(command -v sops) "\$@" ;;
esac
echo "decrypt failed" >&2
exit 1
EOF
chmod +x "$tmp/bin/sops"
PATH="$tmp/bin:$PATH" SOPS_AGE_KEY_FILE="$tmp/age.txt" run_secrets
rc=$?
[ "$rc" -ne 0 ] || fail "(e) decrypt failure was not reported (exit 0)"
grep -q 'failed to update' "$tmp/out" ||
  fail "(e) reported the wrong failure: $(cat "$tmp/out")"
cmp -s "$tmp/before" "$fx/secrets.yaml" ||
  fail "(e) secrets.yaml was modified despite the decrypt failure"
[ -z "$(ls -A "$tmp/tmpdir")" ] ||
  fail "(e) temp files left behind: $(ls -A "$tmp/tmpdir")"

echo "ok: test-secrets-edit"
