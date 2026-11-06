# shellcheck shell=bash
# Output helpers shared by install.sh and uninstall.sh.
# shellcheck disable=SC2034  # RED is used by uninstall.sh only.

# tput fails without a terminal (TERM unset/dumb, piped CI); under set -e that
# must not kill the script, so colours just degrade to empty.
RED=$(tput setaf 1 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
BLUE=$(tput setaf 4 2>/dev/null || true)
UNDERLINE=$(tput smul 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

log() { echo "${BLUE}${UNDERLINE}$1${RESET}"; }
warn() { echo "${YELLOW}$1${RESET}"; }
