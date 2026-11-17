{ pkgs, lib, config, ... }:
let
  # mempalace memory MCP server, same definition as pi's in mcp.nix (kept in
  # sync by hand; it's one attrset). Run through uv because mempalace isn't in
  # nixpkgs; pinned so a launch can't pull whatever PyPI serves today.
  mempalaceServer = {
    type = "stdio";
    command = "${pkgs.uv}/bin/uv";
    args = [ "run" "--with" "mempalace==3.11.0" "python" "-m" "mempalace.mcp_server" ];
    env.PATH = "${pkgs.uv}/bin:/usr/bin:/bin";
  };
in
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

  # Register the mempalace MCP server in ~/.claude.json. Claude Code owns that
  # file (it rewrites it at runtime, like settings.json), so we don't symlink or
  # overwrite it — we merge just the one key with jq and leave everything else
  # untouched. Re-applied every switch so a version bump above propagates. jq by
  # store path for the GUI-PATH reason noted in mcp.nix. pi's copy of this server
  # lives in mcp.nix; Claude keeps its own because it ignores ~/.config/mcp.
  home.activation.claudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeJson="${config.home.homeDirectory}/.claude.json"
    [ -e "$claudeJson" ] || $DRY_RUN_CMD cp ${pkgs.writeText "claude.json" "{}"} "$claudeJson"
    if [ -e "$claudeJson" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.jq}/bin/jq --argjson s '${builtins.toJSON mempalaceServer}' \
        '.mcpServers.mempalace = $s' "$claudeJson" > "$tmp"; then
        $DRY_RUN_CMD cp "$tmp" "$claudeJson"
      fi
      rm -f "$tmp"
    fi
  '';
}
