# Headroom: context compression proxy for AI agents.
# Not in nixpkgs and pulls heavy ML deps (torch/transformers), so it is
# installed into an isolated venv via a home-manager activation script
# rather than packaged purely. Declarative trigger + version pin; pip
# underneath. Bump `pin` to upgrade. Use: `headroom wrap claude`.
#
# Also runs a persistent optimization proxy for pi as a launchd agent,
# bound to 127.0.0.1:8788 — deliberately not 8787, which `headroom wrap
# claude` manages with its own ref-counted lifecycle. The proxy needs no
# secrets: it reads the Mimir upstream URL at runtime from the sops-rendered
# file, and forwards the client's Authorization header upstream. pi reaches
# it via the `cubbit-headroom` provider (pi.nix).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  venv = "${config.home.homeDirectory}/.local/share/headroom-venv";
  bin = "${config.home.homeDirectory}/.local/bin/headroom";
  pin = "0.30.0";
  proxyPort = 8788;
  mimirUrlFile = "${config.home.homeDirectory}/.config/opencode/mimir-base-url";
  logDir = "${config.home.homeDirectory}/.headroom/logs";
in
{
  home.activation.headroom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! "${venv}/bin/headroom" --version 2>/dev/null | grep -q "${pin}"; then
      $DRY_RUN_CMD ${pkgs.python313}/bin/python3 -m venv --clear "${venv}"
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet --upgrade pip
      $DRY_RUN_CMD "${venv}/bin/pip" install --quiet "headroom-ai[all]==${pin}"
    fi
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sf "${venv}/bin/headroom" "${bin}"
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  # Persistent optimization proxy. KeepAlive=true covers first-boot races:
  # until the headroom symlink and the sops-rendered Mimir URL both exist,
  # the script sleeps and exits so launchd retries. Proxy logs to
  # ~/.headroom/logs/proxy.log; stdout/stderr land in the launchd log files.
  launchd.agents.headroom-proxy = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          if [ ! -x "${bin}" ] || [ ! -s "${mimirUrlFile}" ]; then sleep 15; exit 1; fi
          exec "${bin}" proxy --port ${toString proxyPort} \
            --openai-api-url "$(cat "${mimirUrlFile}")"
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables.PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
      StandardOutPath = "${logDir}/launchd-proxy.out.log";
      StandardErrorPath = "${logDir}/launchd-proxy.err.log";
    };
  };
}
