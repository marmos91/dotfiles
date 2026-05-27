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
  # https://github.com/open-gsd/get-shit-done-redux
  home.activation.installGSD = lib.hm.dag.entryAfter [ "installClaude" ] ''
    (
      export PATH="${pkgs.nodejs}/bin:${homeDirectory}/.claude/local/bin:${homeDirectory}/.local/bin:$PATH"
      # npm_config_prefix must point to a writable location — the Nix store is read-only
      export npm_config_prefix="${homeDirectory}/.local"

      if [ ! -d "${homeDirectory}/.claude/skills/gsd-help" ]; then
        echo "Installing Get Shit Done for Claude Code (user)..."
        HOME="${homeDirectory}" npx --yes @opengsd/get-shit-done-redux@latest --claude --global
      else
        echo "Get Shit Done already installed for user, skipping..."
      fi
    )
  '';}
