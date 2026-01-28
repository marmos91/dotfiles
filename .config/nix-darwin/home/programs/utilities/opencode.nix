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
          glm = {
            name = "GLM";
            reasoning = true;
            tool_call = true;
          };
        };
      };
    };
    model = "cubbit/glm";
  };
}
