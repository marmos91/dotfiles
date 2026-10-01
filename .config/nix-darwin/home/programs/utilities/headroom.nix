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
#
# Proxy flags are not defaults, each one fixes a measured failure:
#   --no-rate-limit            headroom defaults to 60 req/min and 100k
#                              tokens/min. A burst of 70 requests returned
#                              9x HTTP 429; on 2026-09-10 that produced 379
#                              `429 status code (no body)` failures in pi's
#                              session logs, all on this provider. The gateway
#                              has its own limits, so the local one is only
#                              self-inflicted backpressure.
#   --no-ccr-inject-tool       pi is a streaming client that cannot resolve
#                              the injected headroom_retrieve MCP tool, so
#                              the marker is dead weight in every request.
#
# Do NOT add --request-timeout-seconds here. It looks tempting (the default is
# 300s and Mimir allows 131072 output tokens), but it is httpx's *read* timeout
# -- an inter-chunk gap, not a total-request budget (proxy/server.py builds
# httpx.Timeout(connect=..., read=request_timeout_seconds, ...)). A measured
# reasoning-heavy stream (10473 chunks, 175s total) had a p99 inter-chunk gap of
# 0.23s and a worst gap of 4.9s, so 300s is ~60x the observed worst stall. A
# longer value buys nothing and only lengthens a genuine hang.
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
            --openai-api-url "$(cat "${mimirUrlFile}")" \
            --no-rate-limit \
            --no-ccr-inject-tool
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
