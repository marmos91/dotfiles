{ config, ... }:
{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      cubbit = {
        npm = "@ai-sdk/openai-compatible";
        name = "Cubbit Mimir";
        options = {
          baseURL = "https://mimir.cubbit.dev/v1";
          apiKey = "{file:${config.sops.secrets.mimir_api_key.path}}";
        };
        models = {
          qwen = {
            name = "Qwen3.5-122B";
            reasoning = true;
            tool_call = true;
          };
        };
      };
    };
    model = "cubbit/qwen";
  };
}
