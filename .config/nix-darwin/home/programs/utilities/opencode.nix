# opencode pointed at Cubbit's Mimir gateway.
#
# Mirrors https://mimir.cubbit.dev/.well-known/opencode.json, with two
# deliberate local deviations: baseURL/apiKey come from the sops-rendered
# files (opencode does resolve `{file:...}`, unlike pi), and the theme is
# pinned to Catppuccin Mocha.
#
# Model ids must match what the gateway serves (`GET /v1/models`:
# `vllm/mimir`, `cubbit/mimir-small`) — opencode sends the model key
# verbatim, so a stale id is a hard 404 rather than a silent fallback.
#
# The long timeouts are not optional: `output` is 131072 tokens, and a
# full-length generation comfortably outruns opencode's stock timeout.
{ config, pkgs, lib, ... }:
let
  localBin = "${config.home.homeDirectory}/.local/bin";
  # The gateway takes reasoning effort as a 0-100 number, not a named level.
  thinking = effort: {
    chat_template_kwargs = {
      thinking = true;
      reasoning_effort = effort;
    };
  };
  # Per-model settings opencode has and pi does not.
  opencodeExtras."vllm/mimir" = {
    options = thinking 50;
    variants = {
      none.chat_template_kwargs.thinking = false;
      low = thinking 25;
      high = thinking 50;
      xhigh = thinking 75;
      max = thinking 100;
    };
  };
in
{
  # Same PATH gap as pi.nix: opencode lands in the home-manager profile
  # (/etc/profiles/per-user/$USER/bin), which is not on the PATH of apps
  # launched by launchd — notably Open Design's daemon, so it reports
  # opencode as unavailable. ~/.local/bin is on that PATH.
  # OPEN_DESIGN_AGENT_BINS: opencode
  home.activation.opencode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${localBin}"
    $DRY_RUN_CMD ln -sfn "${pkgs.opencode}/bin/opencode" "${localBin}/opencode"
  '';

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.cubbit = {
      npm = "@ai-sdk/openai-compatible";
      name = "Cubbit Mimir";
      options = {
        baseURL = "{file:${config.sops.secrets.mimir_base_url.path}}";
        apiKey = "{file:${config.sops.secrets.mimir_api_key.path}}";
        timeout = 1800000;
        chunkTimeout = 300000;
        headers."x-bf-passthrough-extra-params" = "true";
      };
      models = lib.listToAttrs (
        map (m: {
          name = m.id;
          value = {
            inherit (m) name;
            attachment = true;
            modalities = {
              inherit (m) input;
              output = [ "text" ];
            };
            limit = {
              context = m.contextWindow;
              output = m.maxTokens;
            };
          } // (opencodeExtras.${m.id} or { });
        }) (import ./mimir-models.nix)
      );
    };
    model = "cubbit/vllm/mimir";
    share = "disabled";
    disabled_providers = [ "opencode" ];
    theme = "catppuccin-mocha";
  };
}
