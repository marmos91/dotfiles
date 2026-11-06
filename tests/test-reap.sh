#!/bin/sh
# Exercises the `reap` helper (home/scripts/reap.nix). Runs the materialised binary,
# so this is a post-rebuild test: `reap` is installed by `rebuild`, not by the
# flake eval.
#
# Regression targets: the tty test was inverted (`[ -t 0 ]` instead of
# `[ ! -t 0 ]`), so the confirm prompt was unreachable and a non-interactive
# caller aborted with exit 1; and `-t` without an argument died under `set -u`.
set -u

fail() { echo "FAIL: $*" >&2; exit 1; }

victim=""
reap=$(command -v reap) || { echo "skip: reap not installed (run rebuild first)"; exit 77; }

tmp=$(mktemp -d)
trap 'if [ -n "$victim" ]; then kill "$victim" 2>/dev/null; fi; rm -rf "$tmp"' EXIT

# Stub `ps` ahead of the real one: the script's awk is a baked store path, but
# `ps` resolves through PATH, so this is the only interception needed.
stop_victim() {
  [ -n "$victim" ] && kill "$victim" 2>/dev/null
  victim=""
}
spawn_victim() {
  # Kill the previous victim first: only one is tracked at a time.
  stop_victim
  # Subshell capture keeps the job-control notice out of the test's output.
  victim=$( { sh -c 'while :; do :; done' >/dev/null 2>&1 & echo $!; } 2>/dev/null )
  sleep 0.2
  mkdir -p "$tmp/bin"
  cat > "$tmp/bin/ps" <<EOF
#!/bin/sh
echo "  PID  PPID %CPU COMMAND"
echo "  $victim     1 99.0 sh -c while :; do :; done"
EOF
  chmod +x "$tmp/bin/ps"
  PATH="$tmp/bin:$PATH"
  export PATH
}

alive() { kill -0 "$victim" 2>/dev/null; }

# (a) non-interactive without -y reports and exits 0, leaving the victim alive
spawn_victim
"$reap" </dev/null >"$tmp/out" 2>&1
rc=$?
[ "$rc" -eq 0 ] || fail "(a) non-interactive run exited $rc: $(cat "$tmp/out")"
grep -q 'dry run' "$tmp/out" || fail "(a) no dry-run report: $(cat "$tmp/out")"
alive || fail "(a) killed the process without being asked"
stop_victim

# (b) -y kills without prompting
spawn_victim
"$reap" -y </dev/null >"$tmp/out" 2>&1
rc=$?
[ "$rc" -eq 0 ] || fail "(b) reap -y exited $rc: $(cat "$tmp/out")"
grep -q 'killed 1' "$tmp/out" || fail "(b) no kill report: $(cat "$tmp/out")"
alive && fail "(b) victim still alive after reap -y"
victim=""

# (c) -t without an argument is a usage error, not an unbound-variable abort
"$reap" -t </dev/null >"$tmp/out" 2>&1
rc=$?
[ "$rc" -eq 1 ] || fail "(c) reap -t (no arg) exited $rc: $(cat "$tmp/out")"
grep -q 'needs a percentage' "$tmp/out" || fail "(c) missing usage message: $(cat "$tmp/out")"

# (d) interactive without -y prompts, and 'n' aborts with the victim alive.
# `script` gives the child a tty so `[ -t 0 ]` is true.
if command -v script >/dev/null; then
  spawn_victim
  printf 'n\n' | script -q /dev/null "$reap" >"$tmp/out" 2>&1
  rc=$?
  grep -q 'kill these' "$tmp/out" || fail "(d) prompt never printed: $(cat "$tmp/out")"
  grep -q 'aborted' "$tmp/out" || fail "(d) no abort message: $(cat "$tmp/out")"
  [ "$rc" -eq 1 ] || fail "(d) answering n exited $rc"
  alive || fail "(d) killed after answering n"
  stop_victim
else
  echo "note: script(1) unavailable, skipping the interactive case"
fi

echo "ok: test-reap"
