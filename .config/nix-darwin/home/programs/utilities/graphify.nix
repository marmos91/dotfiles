# Graphify: turns any folder (code, docs, images) into a queryable knowledge
# graph, exposed to Claude Code as the `/graphify` skill. Distributed as a pip
# package (`graphifyy`), not in nixpkgs, so it is installed into an isolated
# venv via a home-manager activation script — same pattern as headroom.nix.
#
# The install is hash-pinned (graphify-requirements.txt, --require-hashes) so a
# republished artifact cannot land. The skill text is vendored in
# graphify-skill/ and owned by home-manager: `graphify install --platform
# claude` is deliberately not run, because it lets the pip package rewrite the
# skill and append to ~/.claude/CLAUDE.md, i.e. the agent's system prompt.
#
# To bump: change `pin`, regenerate the requirements (pip freeze in a scratch
# venv, then every wheel hash from PyPI), and recopy skill.md plus
# skills/claude/references/ from the new package into graphify-skill/.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  venv = "${config.home.homeDirectory}/.local/share/graphify-venv";
  bin = "${config.home.homeDirectory}/.local/bin/graphify";
  pin = "0.9.5";
in
{
  home.file.".claude/skills/graphify".source = ./graphify-skill;

  home.activation.graphify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! "${venv}/bin/graphify" --version 2>/dev/null | grep -q "${pin}"; then
      $DRY_RUN_CMD ${pkgs.python313}/bin/python3 -m venv --clear "${venv}"
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet --require-hashes -r ${./graphify-requirements.txt}
    fi
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sf "${venv}/bin/graphify" "${bin}"
  '';
}
