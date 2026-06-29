# Headroom: context compression proxy for AI agents.
# Not in nixpkgs and pulls heavy ML deps (torch/transformers), so it is
# installed into an isolated venv via a home-manager activation script
# rather than packaged purely. Declarative trigger + version pin; pip
# underneath. Bump `pin` to upgrade. Use: `headroom wrap claude`.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  venv = "${config.home.homeDirectory}/.local/share/headroom-venv";
  bin = "${config.home.homeDirectory}/.local/bin/headroom";
  pin = "0.27.0";
in
{
  home.activation.headroom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! "${venv}/bin/headroom" --version 2>/dev/null | grep -q "${pin}"; then
      $DRY_RUN_CMD ${pkgs.python313}/bin/python3 -m venv "${venv}"
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet --upgrade pip
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet "headroom-ai[all]==${pin}"
    fi
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sf "${venv}/bin/headroom" "${bin}"
  '';
}
