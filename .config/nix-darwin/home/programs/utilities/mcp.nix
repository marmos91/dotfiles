# Shared MCP server registry for pi (pi-mcp-adapter) and Claude Code.
#
# Rendered via sops because google-docs carries OAuth client credentials
# (same sops secrets Claude already uses). tokensave/headroom are local stdio
# binaries; context7 is a remote HTTP MCP. Figma's remote MCP is gated to its
# MCP Catalog (DCR 403 for unlisted clients) and the desktop route needs the
# Figma app — add framelink figma-developer-mcp (npx, FIGMA_API_KEY) if ever
# needed. OAuth tokens live in the OS keychain, never here.
{
  config,
  ...
}:
{
  sops.templates."mcp.json" = {
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
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
      };
    };
  };
}
