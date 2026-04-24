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
        export PATH="${pkgs.nodejs}/bin:${homeDirectory}/.claude/local/bin:${homeDirectory}/.local/bin:$PATH"
        # npm_config_prefix must point to a writable location — the Nix store is read-only
        export npm_config_prefix="${homeDirectory}/.local"
        HOME="${homeDirectory}" npx --yes get-shit-done-cc --claude --global
      else
        echo "Get Shit Done already installed for user, skipping..."
      fi

      # Installer ships cli.js without the executable bit — fix it so the gsd-sdk symlink works
      gsd_cli="${homeDirectory}/.local/lib/node_modules/@gsd-build/sdk/dist/cli.js"
      if [ -f "$gsd_cli" ] && [ ! -x "$gsd_cli" ]; then
        chmod +x "$gsd_cli"
      fi
    )
  '';}
