# claude-mimir: run Mimir models as Claude Code subagents
# (https://github.com/didimelli/claude-mimir, pinned by flake.lock).
#
# A local gateway, it-router, listens on 127.0.0.1:4000 and routes each
# request by its `model`: `cubbit/*` to Mimir, everything else to
# api.anthropic.com unchanged (same headers, so the Claude subscription login
# keeps working). `claude-mimir` is `claude` pointed at it; plain `claude`
# still goes straight to Anthropic, so only those sessions depend on it.
# The subagents mimir, mimir-pro and mimir-slim select the Mimir models.
#
# MIMIR_API=openai: the gateway translates to Mimir's /v1, the base URL that
# sops already holds. On /anthropic, mimir-pro sometimes reasons until
# max_tokens and returns an empty turn (upstream README, issue #4: 4 of 7
# probe runs on /anthropic, 0 of 7 on /v1 with an effort set).
#
# No headroom in this path: `headroom wrap` sets ANTHROPIC_BASE_URL itself.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  src = inputs.claude-mimir;
  it-router = pkgs.buildGoModule {
    pname = "it-router";
    version = "unstable-${src.shortRev or "dirty"}";
    inherit src;
    vendorHash = null; # standard library only
    # The tests start local HTTP servers, which the darwin sandbox blocks.
    doCheck = false;
    postInstall = "mv $out/bin/claude-mimir $out/bin/it-router";
    meta.mainProgram = "it-router";
  };
  port = 4000;
  logDir = "${config.home.homeDirectory}/Library/Logs";
  keyFile = config.sops.secrets.mimir_api_key.path;
  urlFile = config.sops.secrets.mimir_base_url.path;

  claude-mimir = pkgs.writeShellScriptBin "claude-mimir" ''
    # Claude Code routed through it-router, for sessions with Mimir subagents.
    if ! ${pkgs.curl}/bin/curl -fsS -m 2 -o /dev/null http://127.0.0.1:${toString port}/router/health; then
      echo "claude-mimir: it-router is not answering on :${toString port}" >&2
      echo "claude-mimir: launchctl print gui/$(id -u)/org.nix-community.home.it-router" >&2
      exit 1
    fi
    export ANTHROPIC_BASE_URL=http://127.0.0.1:${toString port}
    # Claude Code assumes 200k for model ids it does not know and compacts
    # Mimir subagents there. This applies only to unrecognised ids.
    export CLAUDE_CODE_MAX_CONTEXT_TOKENS=''${CLAUDE_CODE_MAX_CONTEXT_TOKENS:-1048576}
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
    unset ANTHROPIC_CUSTOM_HEADERS
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ claude-mimir ];

  home.file = lib.genAttrs [ "mimir" "mimir-pro" "mimir-slim" ] (n: {
    target = ".claude/agents/${n}.md";
    source = "${src}/agents/${n}.md";
  });

  # KeepAlive covers first-boot races: until sops has rendered the key and
  # the URL, the script sleeps and exits so launchd retries.
  launchd.agents.it-router = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          if [ ! -s "${keyFile}" ] || [ ! -s "${urlFile}" ]; then sleep 15; exit 1; fi
          MIMIR_API_KEY="$(cat "${keyFile}")" MIMIR_API=openai \
          MIMIR_OPENAI_URL="$(cat "${urlFile}")" \
          exec ${lib.getExe it-router} --port ${toString port} --log "${logDir}/it-router.jsonl"
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/it-router.out.log";
      StandardErrorPath = "${logDir}/it-router.err.log";
    };
  };
}
