# Find and kill agent-spawned shells orphaned to PID 1 that are burning CPU.
# pi and Claude Code spawn bash-tool shells detached (setsid); when the
# parent agent dies, the shell and its `(while :; do :; done)` load jobs
# reparent to PID 1 and spin forever. Upstream: earendil-works/pi#3057.
{ pkgs }:
pkgs.writeShellScriptBin "reap" ''
  set -u
  THRESH=20
  ASSUME_YES=0
  DRY=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -t)
        # gawk compares "$3+0 >= t", so a non-numeric t matches every
        # candidate and -y would kill all of them. The "x" prefix keeps
        # the empty case expressible inside this Nix string.
        case "x''${2:-}" in
          x | x*[!0-9]*) echo "-t needs a percentage" >&2; exit 1 ;;
        esac
        THRESH="$2"
        shift 2
        ;;
      -y) ASSUME_YES=1; shift ;;
      --dry-run) DRY=1; shift ;;
      -h|--help)
        echo "usage: reap [-t PCT] [-y] [--dry-run]"
        echo "  kill agent shells orphaned to PID 1 (PPID 1) burning CPU"
        echo "  -t PCT  CPU% threshold (default 20)"
        echo "  -y      kill without prompting"
        exit 0 ;;
      *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
  done
  # non-interactive and not told to kill -> just report
  if [ ! -t 0 ] && [ "$ASSUME_YES" != 1 ]; then DRY=1; fi

  # PPID 1 = orphaned. Only agent shells (zsh/bash/sh -c), only busy ones.
  CANDIDATES=$(ps -eo pid,ppid,pcpu,command | ${pkgs.gawk}/bin/awk -v t="$THRESH" '
    $2 == 1 && $3+0 >= t && /(zsh|bash|sh) -c/ { print $1, $3, substr($0, index($0,$4)) }
  ')

  if [ -z "$CANDIDATES" ]; then
    echo "clean: no orphaned shells above ''${THRESH}% CPU"
    exit 0
  fi

  COUNT=$(printf '%s\n' "$CANDIDATES" | wc -l | tr -d ' ')
  echo "found $COUNT orphaned shell(s) above ''${THRESH}% CPU:"
  echo
  printf '%s\n' "$CANDIDATES" | while read -r pid pcpu cmd; do
    sig=""
    case "$cmd" in *'while :'*|*'while true'*) sig="  <-- busy-loop spinner" ;; esac
    printf '  pid %-8s %5s%%  %s%s\n' "$pid" "$pcpu" "$(printf '%s' "$cmd" | cut -c1-100)" "$sig"
  done
  echo

  PIDS=$(printf '%s\n' "$CANDIDATES" | ${pkgs.gawk}/bin/awk '{print $1}')
  if [ "$DRY" = 1 ]; then
    echo "dry run. to kill:  reap -y"
    exit 0
  fi

  if [ "$ASSUME_YES" != 1 ]; then
    printf 'kill these %s process(es)? [y/N] ' "$COUNT"
    read -r ans
    case "$ans" in y|Y|yes) ;; *) echo "aborted"; exit 1 ;; esac
  fi

  # shellcheck disable=SC2086
  kill -9 $PIDS 2>/dev/null
  sleep 1
  LEFT=$(ps -eo pid,ppid,pcpu,command | ${pkgs.gawk}/bin/awk -v t="$THRESH" '$2==1 && $3+0>=t && /(zsh|bash|sh) -c/' | wc -l | tr -d ' ')
  echo "killed $COUNT; remaining above threshold: $LEFT"
  echo "load average: $(uptime | sed 's/.*load averages*: //')"
''
