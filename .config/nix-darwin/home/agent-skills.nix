{
  lib,
  pkgs,
  inputs,
  ...
}:
# ~/.agents/skills is the cross-harness skill convention (Pi, Cursor, Claude
# Code, OpenCode). Union pstack with the personal skills from github:marmos91/skills,
# so one symlink serves both and neither input owns the whole tree.
# `nix flake update` bumps each input; `rebuild` applies it.
{
  home.file.".agents/skills".source = pkgs.runCommand "agent-skills" { } ''
    mkdir -p $out
    cp -RL "${inputs.pstack}/skills/." $out/
    cp -RL "${inputs.mySkills}/shared/." $out/
    cp -RL "${inputs.mySkills}/pi/." $out/
  '';
}
