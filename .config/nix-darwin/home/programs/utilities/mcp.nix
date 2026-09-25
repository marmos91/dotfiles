# MCP server registry for pi (pi-mcp-adapter). Claude Code keeps its own copy
# in ~/.claude.json, so editing this file does not reach it.
#
# Rendered via sops because google-docs carries OAuth client credentials
# (same sops secrets Claude already uses). tokensave/headroom are local stdio
# binaries; context7 is a remote HTTP MCP. Figma's remote MCP is gated to its
# MCP Catalog (DCR 403 for unlisted clients) and the desktop route needs the
# Figma app — add framelink figma-developer-mcp (npx, FIGMA_API_KEY) if ever
# needed. OAuth tokens live in the OS keychain, never here.
{
  config,
  pkgs,
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
        # Obsidian vault access. The plugin (utilities/obsidian.nix) serves an
        # MCP endpoint on the same listener as its REST API, so there is no
        # child process to spawn. Plain HTTP on 127.0.0.1:27123 rather than the
        # default HTTPS 27124: the TLS leg uses a self-signed certificate that
        # would need trusting per client, and loopback HTTP exposes nothing the
        # local machine could not already read. obsidian.nix forces that
        # listener on.
        #
        # The bearer token is read back from the plugin's own data.json at
        # connect time instead of being duplicated into a sops secret. The
        # plugin generates that key itself on first load, so a copy in sops
        # would mean two sources of truth and a seeding step that has to run
        # before the plugin ever starts — the secret file does not exist yet at
        # that point, because sops-nix installs it asynchronously from a launchd
        # agent. A single leading `!` makes the adapter run the command; `!!`
        # would be the literal string. It must be `bearerToken`, not a header:
        # the `!` marker only takes effect as the value's first character.
        #
        # jq is interpolated by store path rather than taken from PATH: pi may
        # be launched from the GUI, where PATH is /usr/bin:/bin:/usr/sbin:/sbin.
        # Interpolation also puts jq in this generation's closure, so it cannot
        # be collected while the path is still referenced here.
        obsidian = {
          type = "http";
          url = "http://127.0.0.1:27123/mcp/";
          auth = "bearer";
          bearerToken = "!${pkgs.jq}/bin/jq -r '.apiKey' ${config.home.homeDirectory}/Projects/dittofs/docs/.obsidian/plugins/obsidian-local-rest-api/data.json";
        };
      };
    };
  };
}
