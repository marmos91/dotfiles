# pi (pi.dev) coding agent, pointed at Cubbit's Mimir gateway.
#
# models.json is rendered by sops-nix rather than home.file: the Mimir base
# URL and API key are secrets, and pi resolves neither `{file:...}` nor `!cmd`
# in `baseUrl`, so the values have to be substituted at activation time.
#
# settings.json and auth.json are written by pi itself (theme, changelog
# version, OAuth refresh), so they are patched in place instead of symlinked
# into the store — a store symlink would make pi's writeFileSync fail.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  piDir = "${config.home.homeDirectory}/.pi/agent";
  jq = "${pkgs.jq}/bin/jq";
in
{
  sops.templates."pi-models.json" = {
    path = "${piDir}/models.json";
    mode = "0600";
    content = builtins.toJSON {
      providers.cubbit = {
        name = "Cubbit Mimir";
        baseUrl = config.sops.placeholder.mimir_base_url;
        apiKey = config.sops.placeholder.mimir_api_key;
        api = "openai-completions";
        # vLLM behind the gateway: no `developer` role.
        compat.supportsDeveloperRole = false;
        models = [
          {
            id = "vllm/mimir";
            name = "Mimir";
            reasoning = true;
            contextWindow = 1048576;
            maxTokens = 64000;
          }
          {
            id = "cubbit/mimir-small";
            name = "Mimir Small";
            reasoning = true;
            contextWindow = 262144;
            maxTokens = 32000;
          }
        ];
      };
    };
  };

  # Drop the Anthropic credential so Opus is never reachable from pi, and
  # steer the default off Anthropic without clobbering a deliberate choice.
  home.activation.pi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${piDir}"

    auth="${piDir}/auth.json"
    if [ -f "$auth" ] && ${jq} -e 'has("anthropic")' "$auth" >/dev/null; then
      ${jq} 'del(.anthropic)' "$auth" > "$auth.new"
      chmod 600 "$auth.new"
      $DRY_RUN_CMD mv "$auth.new" "$auth"
    fi

    settings="${piDir}/settings.json"
    [ -f "$settings" ] || echo '{}' > "$settings"
    ${jq} 'if (.defaultProvider // "anthropic") == "anthropic"
           then .defaultProvider = "cubbit" | .defaultModel = "vllm/mimir"
           else . end' "$settings" > "$settings.new"
    $DRY_RUN_CMD mv "$settings.new" "$settings"
  '';
}
