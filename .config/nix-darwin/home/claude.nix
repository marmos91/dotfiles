{ pkgs, lib, config, homeDirectory, ... }:
{
  # Install Get Shit Done for Claude Code
  # https://github.com/glittercowboy/get-shit-done
  home.activation.installGSD = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.nodejs}/bin:$PATH"

    # Install for current user
    if [ ! -d "${homeDirectory}/.claude/commands/gsd" ]; then
      echo "Installing Get Shit Done for Claude Code (user)..."
      HOME="${homeDirectory}" ${pkgs.nodejs}/bin/npx --yes get-shit-done-cc --claude --global
    else
      echo "Get Shit Done already installed for user, skipping..."
    fi

    # Install for root user
    if [ ! -d "/var/root/.claude/commands/gsd" ]; then
      echo "Installing Get Shit Done for Claude Code (root)..."
      /usr/bin/sudo HOME="/var/root" ${pkgs.nodejs}/bin/npx --yes get-shit-done-cc --claude --global
    else
      echo "Get Shit Done already installed for root, skipping..."
    fi
  '';
}
