{ pkgs, lib, config, homeDirectory, ... }:
{
  # Install Claude Code via official installer
  home.activation.installClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${pkgs.curl}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin:${homeDirectory}/.local/bin:$PATH"
      if ! command -v claude &>/dev/null; then
        echo "Installing Claude Code via official installer..."
        curl -fsSL https://claude.ai/install.sh | sh
      else
        echo "Claude Code already installed, skipping..."
      fi
    )
  '';

  # Install Get Shit Done for Claude Code
  # https://github.com/glittercowboy/get-shit-done
  home.activation.installGSD = lib.hm.dag.entryAfter [ "installClaude" ] ''
    (
      if [ ! -d "${homeDirectory}/.claude/commands/gsd" ]; then
        echo "Installing Get Shit Done for Claude Code (user)..."
        export PATH="${pkgs.nodejs}/bin:${homeDirectory}/.claude/local/bin:$PATH"
        HOME="${homeDirectory}" npx --yes get-shit-done-cc --claude --global
      else
        echo "Get Shit Done already installed for user, skipping..."
      fi
    )
  '';

  # Re-apply any-buddy companion patch after Claude updates
  # https://github.com/cpaczek/any-buddy
  # Only runs if a buddy profile already exists — create one once with `npx any-buddy`
  # and this script will keep it patched across Claude versions automatically.
  home.activation.applyClaudeBuddy = lib.hm.dag.entryAfter [ "installClaude" ] ''
    (
      if [ -f "${homeDirectory}/.claude-code-any-buddy.json" ]; then
        export PATH="${pkgs.nodejs}/bin:${homeDirectory}/.local/bin:$PATH"
        currentVersion="$(readlink "${homeDirectory}/.local/share/claude/current" 2>/dev/null || true)"
        appliedTo="$(${pkgs.jq}/bin/jq -r '.appliedTo // ""' "${homeDirectory}/.claude-code-any-buddy.json" 2>/dev/null || true)"
        if [ -n "$currentVersion" ] && [ "$appliedTo" = "$currentVersion" ]; then
          echo "any-buddy already applied to current Claude version, skipping..."
        else
          echo "Re-applying any-buddy companion to Claude binary..."
          HOME="${homeDirectory}" npx --yes any-buddy@latest apply || \
            echo "any-buddy apply failed (non-fatal) — run 'npx any-buddy apply' manually"
        fi
      fi
    )
  '';
}
