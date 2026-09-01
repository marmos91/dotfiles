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
}
