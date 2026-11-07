# The Mimir model catalog, in pi's shape (mirrors
# <mimir base URL>/.well-known/pi-models.json). pi.nix renders it as is;
# opencode.nix derives its names and limits from it.
[
  {
    id = "vllm/mimir";
    name = "Mimir";
    reasoning = true;
    input = [ "text" "image" ];
    contextWindow = 917504;
    maxTokens = 131072;
    # Levels the gateway has no mapping for send no reasoning_effort at
    # all, leaving the server default (thinking on, medium-high).
    thinkingLevelMap = {
      off = "none";
      minimal = null;
      low = "low";
      medium = null;
      high = "high";
      xhigh = "xhigh";
      max = "max";
    };
    samplingParams = {
      temperature = 1.0;
      top_p = 0.95;
    };
  }
  {
    id = "cubbit/mimir-small";
    name = "Mimir Small";
    # Upstream /pi-models.json says reasoning: true with a thinkingLevelMap;
    # this said false, which silently hid thinking from the model and
    # disabled pi's reasoning handling for it.
    reasoning = true;
    input = [ "text" "image" ];
    contextWindow = 229376;
    maxTokens = 32768;
    thinkingLevelMap = {
      off = "none";
      minimal = "low";
      low = "low";
      medium = "medium";
      high = "medium";
      xhigh = "xhigh";
      max = "xhigh";
    };
  }
]
