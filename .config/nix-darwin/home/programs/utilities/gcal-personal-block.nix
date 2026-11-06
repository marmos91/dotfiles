# gcal-personal-block: mirror Family calendar events onto the work calendar
# as generic "Personal Commitment" blocks (replaces reclaim.ai's core feature).
#
# The script reads sops-rendered identifiers from ~/.config/gcal-personal-block/
# (client-id, client-secret, family-cal, work-email; see home/secrets/) plus
# the work OAuth token at ~/.config/google-docs-mcp/calendar-work-token.json.
# Family is read-only; only the work primary calendar is written. Tokens and
# identifiers are NOT in this repo.
#
# Runs hourly via launchd. Idempotent: each run upserts/removes placeholders
# keyed by the Family event UID (extendedProperties.private), so moved or
# deleted Family events are reflected on the next run.
{ config, lib, pkgs, ... }:
let
  # withPackages builds ONE interpreter that carries the deps; separate
  # python313Packages.* derivations in home.packages are not importable.
  py = pkgs.python313.withPackages (ps: [
    ps.google-api-python-client
    ps.google-auth-oauthlib
  ]);
  script = "${config.home.homeDirectory}/.dotfiles/.local/bin/gcal-personal-block";
  logDir = "${config.home.homeDirectory}/.local/state/gcal-personal-block/logs";
  # a dead token or any other failure must be visible: the err log is where
  # failures go to be ignored, so surface a macOS notification on non-zero exit
  notifyFail = pkgs.writeShellScriptBin "gcal-personal-block-notify-fail" ''
    if ! "$@"; then
      /usr/bin/osascript -e 'display notification "Run ~/.dotfiles/.local/bin/gcal-personal-block --run to see the error" with title "gcal sync failed" sound name "Basso"'
      exit 1
    fi
  '';
in
{
  home.activation.gcal-personal-block = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  launchd.agents.gcal-personal-block = {
    enable = true;
    config = {
      ProgramArguments = [
        "${notifyFail}/bin/gcal-personal-block-notify-fail"
        "${py}/bin/python3"
        "${script}"
        "--run"
      ];
      StartInterval = 3600; # hourly
      RunAtLoad = false; # don't stack with the hourly interval on boot
      StandardOutPath = "${logDir}/sync.log";
      StandardErrorPath = "${logDir}/sync.err.log";
    };
  };
}
