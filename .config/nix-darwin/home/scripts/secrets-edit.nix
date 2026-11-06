
# `secrets edit <key>` lives in one script rather than in each shell's
# function: bash has no function-scoped trap — a RETURN trap stays
# installed and re-fires on every later call of any function. `sops set`
# does the decrypt → patch → re-encrypt, so no plaintext copy of the whole
# file is written; it rewrites its target in place, so it works on a copy
# that is renamed over secrets.yaml only on success.
{ pkgs }:
pkgs.writeShellScriptBin "secrets-edit" ''
  set -euo pipefail

  secrets_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/nix-darwin/home/secrets"
  f="$secrets_dir/secrets.yaml"
  key="''${1:-}"

  # No key: edit the whole file, as before.
  if [ -z "$key" ]; then
    exec sops "$f"
  fi

  tmp=$(mktemp)
  # Same dir so the mv is a rename; .yaml suffix because sops picks the
  # format from the extension.
  new="$secrets_dir/.secrets-edit.yaml"
  trap 'rm -f "$tmp" "$new"' EXIT
  # `sops set` creates a missing key instead of failing, so read the current
  # value first: that is what rejects a typo.
  if ! sops -d --extract "[\"$key\"]" "$f" > "$tmp" 2>/dev/null; then
    echo "Secret '$key' not found" >&2
    exit 1
  fi
  # An editor that crashes or is killed after truncating the scratch file
  # must not be read back as the new value.
  if ! "''${EDITOR:-nvim}" "$tmp"; then
    echo "editor failed: $f left unchanged" >&2
    exit 1
  fi
  if [ ! -s "$tmp" ]; then
    echo "empty value: $f left unchanged" >&2
    exit 1
  fi
  # JSON-encode the file contents so multi-line values stay strings and the
  # editor's trailing newline is dropped.
  cp "$f" "$new"
  if ! ${pkgs.jq}/bin/jq -Rs 'rtrimstr("\n")' "$tmp" | sops set --value-stdin "$new" "[\"$key\"]"; then
    echo "failed to update '$key': $f left unchanged" >&2
    exit 1
  fi
  mv "$new" "$f"
  echo "Secret '$key' updated"
''
