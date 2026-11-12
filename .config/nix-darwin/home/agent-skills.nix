{
  lib,
  pkgs,
  inputs,
  ...
}:
# ~/.agents/skills is the cross-harness skill convention (Pi, Cursor, Claude
# Code, OpenCode). It holds pstack only.
# My own skills (github:marmos91/skills, pinned to a release tag in flake.nix)
# go through the package installer, the same one as
# `npx @marmos91/skills install`: it copies each skill into ~/.claude/skills
# and ~/.pi/agent/skills and links its CLIs into ~/.local/bin. A rebuild
# replaces the dev links that ./install.sh made in a clone.
# `nix flake update` bumps each input; `rebuild` applies it.
{
  home.file.".agents/skills".source = pkgs.runCommand "agent-skills" { } ''
    mkdir -p $out
    cp -RL "${inputs.pstack}/skills/." $out/
  '';

  home.activation.mySkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.nodejs_24}/bin/node ${inputs.mySkills}/bin/skills.mjs install --claude --pi
  '';
}
