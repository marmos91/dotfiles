# gcal-personal-block: mirror Family calendar events onto the work calendar
# as generic "Personal Commitment" blocks (replaces reclaim.ai's core feature).
#
# The script reads ~/.config/google-docs-mcp/{calendar,calendar-work}-token.json
# (OAuth via the Mimir Cloud project). Family is read-only; only the work
# primary calendar is written. Tokens are NOT in this repo — they live in
# ~/.config un-managed, like the google-docs-mcp token.json.
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
in
{
  home.activation.gcal-personal-block = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  launchd.agents.gcal-personal-block = {
    enable = true;
    config = {
      ProgramArguments = [
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
