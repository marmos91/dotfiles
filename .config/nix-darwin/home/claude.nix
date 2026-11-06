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
}
