{ pstackSrc, ... }:
# Agent skill conventions (Pi, Cursor, Claude Code, OpenCode, ...) read from
# ~/.agents/skills. Pointing at the flake input makes `nix flake update` +
# `rebuild` the upgrade path instead of vendoring the source.
{
  home.file.".agents/skills".source = "${pstackSrc}/skills";
}
