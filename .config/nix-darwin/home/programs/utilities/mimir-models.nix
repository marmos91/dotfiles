# The Mimir model catalog, in pi's shape (mirrors
# <mimir base URL>/.well-known/pi-models.json). pi.nix renders it as is;
# opencode.nix derives its names and limits from it.
#
# Ids are the manifest's (`cubbit/mimir`, `cubbit/mimir-pro`,
# `cubbit/mimir-slim`). The gateway also still answers the older
# `vllm/mimir` and `cubbit/mimir-small`, but pi and opencode only offer
# what is listed here, and the live pi settings already default to
# `cubbit/mimir-pro`.
[
  {
    id = "cubbit/mimir";
    name = "Mimir";
    reasoning = true;
    input = [ "text" "image" ];
    contextWindow = 917504;
    maxTokens = 131072;
    # Levels the gateway has no mapping for send no reasoning_effort at
    # all, leaving the server default (thinking on, medium-high). The
    # manifest maps minimal/medium to "low"; this keeps the server default.
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
    # As the manifest: no "off" level and no sampling params.
    id = "cubbit/mimir-pro";
    name = "Mimir Pro";
    reasoning = true;
    input = [ "text" "image" ];
    contextWindow = 917504;
    maxTokens = 131072;
    thinkingLevelMap = {
      off = null;
      minimal = "low";
      low = "low";
      medium = "high";
      high = "high";
      xhigh = "max";
      max = "max";
    };
  }
  {
    id = "cubbit/mimir-slim";
    name = "Mimir Slim";
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
