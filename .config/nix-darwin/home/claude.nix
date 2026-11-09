{ pkgs, lib, config, ... }:
{
  # Claude Code CLI from nixpkgs — hash-verified by the flake lock + binary
  # cache. Replaces the old `curl https://claude.ai/install.sh | sh`
  # activation, which executed unverified remote code on every switch.
  home.packages = [ pkgs.claude-code ];

  # `env.nix` puts ~/.local/bin ahead of the home-manager profile, so a vendor
  # install there (`claude.ai/install.sh`) would shadow the pinned binary and
  # keep self-updating. Repoint it at the nixpkgs build so the pinned one is
  # what actually runs (same shape as the pi link in pi.nix).
  home.activation.claude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sfn "${pkgs.claude-code}/bin/claude" "${config.home.homeDirectory}/.local/bin/claude"
  '';

  # Static global instructions — pure text that Claude only ever reads, so a
  # read-only store symlink is safe. CLAUDE.md pulls in RTK.md via its @import;
  # rules/pstack-models.md configures the pstack skill's per-role models.
  home.file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
  home.file.".claude/RTK.md".source = ./claude/RTK.md;
  home.file.".claude/rules/pstack-models.md".source = ./claude/rules/pstack-models.md;

  # settings.json is NOT symlinked: Claude rewrites it at runtime (model,
  # effortLevel, editorMode, tui toggles from the TUI), which a read-only store
  # path would break. Seed it on a fresh machine instead, and never clobber a
  # live file — so local edits and runtime writes both survive.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${config.home.homeDirectory}/.claude/settings.json" ]; then
      $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.claude"
      $DRY_RUN_CMD cp ${./claude/settings.json} "${config.home.homeDirectory}/.claude/settings.json"
      $DRY_RUN_CMD chmod u+w "${config.home.homeDirectory}/.claude/settings.json"
    fi
  '';
}
