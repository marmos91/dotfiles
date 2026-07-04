# Graphify: turns any folder (code, docs, images) into a queryable knowledge
# graph, exposed to Claude Code as the `/graphify` skill. Distributed as a pip
# package (`graphifyy`), not in nixpkgs, so it is installed into an isolated
# venv via a home-manager activation script — same pattern as headroom.nix.
# Bump `pin` to upgrade. The second step registers the skill with Claude Code
# (`graphify install`); it appends to ~/.claude/CLAUDE.md idempotently.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  venv = "${config.home.homeDirectory}/.local/share/graphify-venv";
  bin = "${config.home.homeDirectory}/.local/bin/graphify";
  skillVersion = "${config.home.homeDirectory}/.claude/skills/graphify/.graphify_version";
  pin = "0.9.5";
in
{
  home.activation.graphify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! "${venv}/bin/graphify" --version 2>/dev/null | grep -q "${pin}"; then
      $DRY_RUN_CMD ${pkgs.python313}/bin/python3 -m venv "${venv}"
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet --upgrade pip
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet "graphifyy==${pin}"
    fi
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sf "${venv}/bin/graphify" "${bin}"

    # Register / refresh the Claude Code skill only when out of date.
    if ! grep -q "${pin}" "${skillVersion}" 2>/dev/null; then
      $DRY_RUN_CMD "${venv}/bin/graphify" install --platform claude
    fi
  '';
}
