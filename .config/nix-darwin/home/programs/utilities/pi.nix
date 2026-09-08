# pi (pi.dev) coding agent, pointed at Cubbit's Mimir gateway.
#
# models.json is rendered by sops-nix rather than home.file: the Mimir base
# URL and API key are secrets, and pi resolves neither `{file:...}` nor `!cmd`
# in `baseUrl`, so the values have to be substituted at activation time.
#
# Two providers:
#   cubbit           — direct to the Mimir gateway.
#   cubbit-headroom  — through the local headroom compression proxy
#                      (launchd agent in headroom.nix, port 8788). The proxy
#                      forwards the Authorization header upstream, so the
#                      same API key rides along; only the baseUrl differs.
#
# settings.json and auth.json are written by pi itself (theme, changelog
# version, OAuth refresh), so they are patched in place instead of symlinked
# into the store — a store symlink would make pi's writeFileSync fail.
#
# The Catppuccin Mocha theme is a plain home.file symlink: pi only reads
# theme files, so the store is safe.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  piDir = "${config.home.homeDirectory}/.pi/agent";
  jq = "${pkgs.jq}/bin/jq";
  mimirModels = [
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
in
{
  home.file.".pi/agent/themes/catppuccin-mocha.json".text = ''
    {
      "$schema": "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",
      "name": "catppuccin-mocha",
      "vars": {
        "rosewater": "#f5e0dc",
        "flamingo": "#f2cdcd",
        "pink": "#f5c2e7",
        "mauve": "#cba6f7",
        "red": "#f38ba8",
        "maroon": "#eba0ac",
        "peach": "#fab387",
        "yellow": "#f9e2af",
        "green": "#a6e3a1",
        "teal": "#94e2d5",
        "sky": "#89dceb",
        "sapphire": "#74c7ec",
        "blue": "#89b4fa",
        "lavender": "#b4befe",
        "text": "#cdd6f4",
        "subtext1": "#bac2de",
        "subtext0": "#a6adc8",
        "overlay2": "#9399b2",
        "overlay1": "#7f849c",
        "overlay0": "#6c7086",
        "surface2": "#585b70",
        "surface1": "#45475a",
        "surface0": "#313244",
        "base": "#1e1e2e",
        "mantle": "#181825",
        "crust": "#11111b"
      },
      "colors": {
        # Matches home/catppuccin.nix (accent = "lavender" everywhere else).
        "accent": "lavender",
        "border": "surface1",
        "borderAccent": "lavender",
        "borderMuted": "surface0",
        "success": "green",
        "error": "red",
        "warning": "yellow",
        "muted": "overlay1",
        "dim": "overlay0",
        "text": "text",
        "thinkingText": "overlay2",

        "selectedBg": "surface1",
        "scrollbarThumb": "surface1",
        "userMessageBg": "surface0",
        "userMessageText": "text",
        "customMessageBg": "surface0",
        "customMessageText": "text",
        "customMessageLabel": "lavender",
        "toolPendingBg": "mantle",
        "toolSuccessBg": "#1c2a22",
        "toolErrorBg": "#2a1c22",
        "toolTitle": "text",
        "toolOutput": "subtext0",

        "mdHeading": "peach",
        "mdLink": "sky",
        "mdLinkUrl": "overlay0",
        "mdCode": "green",
        "mdCodeBlock": "text",
        "mdCodeBlockBorder": "surface1",
        "mdQuote": "subtext0",
        "mdQuoteBorder": "surface2",
        "mdHr": "surface1",
        "mdListBullet": "mauve",

        "toolDiffAdded": "green",
        "toolDiffRemoved": "red",
        "toolDiffContext": "overlay0",

        "syntaxComment": "overlay0",
        "syntaxKeyword": "mauve",
        "syntaxFunction": "blue",
        "syntaxVariable": "text",
        "syntaxString": "green",
        "syntaxNumber": "peach",
        "syntaxType": "yellow",
        "syntaxOperator": "sky",
        "syntaxPunctuation": "overlay2",

        "thinkingOff": "surface0",
        "thinkingMinimal": "surface1",
        "thinkingLow": "surface2",
        "thinkingMedium": "blue",
        "thinkingHigh": "mauve",
        "thinkingXhigh": "pink",
        "thinkingMax": "red",

        "bashMode": "peach"
      },
      "export": {
        "pageBg": "base",
        "cardBg": "mantle",
        "infoBg": "surface0"
      }
    }
  '';

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
        models = mimirModels;
      };
      providers.cubbit-headroom = {
        name = "Cubbit Mimir (Headroom)";
        baseUrl = "http://127.0.0.1:8788/v1";
        apiKey = config.sops.placeholder.mimir_api_key;
        api = "openai-completions";
        compat.supportsDeveloperRole = false;
        models = mimirModels;
      };
    };
  };

  # MCP servers for pi-mcp-adapter, rendered via sops because google-docs
  # carries OAuth client credentials (already sops secrets — same values
  # Claude uses). tokensave/headroom are local stdio binaries; figma is
  # Figma's official remote MCP, OAuth on first use via /mcp (stored in the
  # OS keychain, never in this file).
  sops.templates."pi-mcp.json" = {
    path = "${config.home.homeDirectory}/.config/mcp/mcp.json";
    mode = "0600";
    content = builtins.toJSON {
      mcpServers = {
        google-docs = {
          command = "npx";
          args = [ "-y" "@a-bonus/google-docs-mcp" ];
          env = {
            GOOGLE_CLIENT_ID = config.sops.placeholder.google_docs_mcp_client_id;
            GOOGLE_CLIENT_SECRET = config.sops.placeholder.google_docs_mcp_client_secret;
          };
        };
        tokensave = {
          type = "stdio";
          command = "${config.home.homeDirectory}/.local/bin/tokensave";
          args = [ "serve" ];
        };
        headroom = {
          type = "stdio";
          command = "${config.home.homeDirectory}/.local/bin/headroom";
          args = [ "mcp" "serve" ];
        };
        figma = {
          url = "https://mcp.figma.com/mcp";
        };
      };
    };
  };

  # Drop the Anthropic credential so Opus is never reachable from pi, and
  # steer the default provider/theme away from built-ins without clobbering
  # a deliberate choice made via /settings.
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
           else . end
           | if (.theme // "dark") == "dark" or .theme == "light"
             then .theme = "catppuccin-mocha" else . end' "$settings" > "$settings.new"
    $DRY_RUN_CMD mv "$settings.new" "$settings"
  '';
}
