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
# settings.json is NOT managed here. pi rewrites it on every launch
# (lastChangelogVersion), so any home.file wiring — store symlink or
# mkOutOfStoreSymlink — leaves the repo permanently dirty and makes every
# runtime toggle look like a pending commit. pi now owns
# ~/.pi/agent/settings.json outright; the repo copy below is a seed that the
# activation script installs only when the live file does not exist yet.
#
# The repo copy is therefore NOT live: edit it to change the defaults, then
# rebuild and delete the live file to re-seed (or edit the live file directly
# and copy it back).
#
# zentui.json is still mkOutOfStoreSymlink into the repo: pi-zentui writes it
# only when the user changes the theme, so it does not churn. It realpathSyncs
# before its temp-file + rename save, hence a repo symlink rather than a store
# one.
#
# Consequence: pi bumps lastChangelogVersion on every upgrade, so the repo copy
# shows up dirty only after a manual copy back. That is expected.
#
# auth.json is mutated by pi (OAuth refresh) and stays unmanaged apart from the
# anthropic strip below. The theme is read-only, so a plain store symlink is fine.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  piDir = "${config.home.homeDirectory}/.pi/agent";
  localBin = "${config.home.homeDirectory}/.local/bin";
  repoRoot = "${config.home.homeDirectory}/.dotfiles";
  jq = "${pkgs.jq}/bin/jq";
  # Mirrors https://mimir.cubbit.dev/.well-known/pi-models.json.
  mimirModels = [
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
      reasoning = false;
      input = [ "text" "image" ];
      contextWindow = 229376;
      maxTokens = 32768;
    }
  ];
in
{
  # Symlink into the repo, not the store: pi-zentui writes this file at runtime
  # and realpathSyncs first, so it must resolve to a writable path.
  home.file.".pi/agent/zentui.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/.pi/agent/zentui.json";

  # Keybindings: shift+enter (native) and ctrl+j already insert newlines; add
  # ctrl+enter, which tmux forwards as CSI-u \x1b[13;5u once extended keys are
  # active. pi only writes this file to migrate legacy names, so a repo
  # symlink stays clean.
  home.file.".pi/agent/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/.pi/agent/keybindings.json";

  # Theme generated from the catppuccin flake's palette, the same source the
  # starship/ghostty/tmux modules use. The two custom surfaces (tool success/
  # error backgrounds) are darkened mixes rather than palette entries.
  home.file.".pi/agent/themes/catppuccin-mocha.json".text = builtins.toJSON (
    let
      p = (builtins.fromJSON (
        builtins.readFile "${config.catppuccin.sources.palette}/palette.json"
      )).mocha.colors;
    in
    {
      "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
      name = "catppuccin-mocha";
      vars = builtins.mapAttrs (_: v: v.hex) p;
      colors = {
        accent = "lavender";
        border = "surface1";
        borderAccent = "lavender";
        borderMuted = "surface0";
        success = "green";
        error = "red";
        warning = "yellow";
        muted = "overlay1";
        dim = "overlay0";
        text = "text";
        thinkingText = "overlay2";
        selectedBg = "surface1";
        scrollbarThumb = "surface1";
        userMessageBg = "surface0";
        userMessageText = "text";
        customMessageBg = "surface0";
        customMessageText = "text";
        customMessageLabel = "lavender";
        toolPendingBg = "mantle";
        toolSuccessBg = "#1c2a22";
        toolErrorBg = "#2a1c22";
        toolTitle = "text";
        toolOutput = "subtext0";
        mdHeading = "peach";
        mdLink = "sky";
        mdLinkUrl = "overlay0";
        mdCode = "green";
        mdCodeBlock = "text";
        mdCodeBlockBorder = "surface1";
        mdQuote = "subtext0";
        mdQuoteBorder = "surface2";
        mdHr = "surface1";
        mdListBullet = "mauve";
        toolDiffAdded = "green";
        toolDiffRemoved = "red";
        toolDiffContext = "overlay0";
        syntaxComment = "overlay0";
        syntaxKeyword = "mauve";
        syntaxFunction = "blue";
        syntaxVariable = "text";
        syntaxString = "green";
        syntaxNumber = "peach";
        syntaxType = "yellow";
        syntaxOperator = "sky";
        syntaxPunctuation = "overlay2";
        thinkingOff = "surface0";
        thinkingMinimal = "surface1";
        thinkingLow = "surface2";
        thinkingMedium = "blue";
        thinkingHigh = "mauve";
        thinkingXhigh = "pink";
        thinkingMax = "red";
        bashMode = "peach";
      };
      export = {
        pageBg = "base";
        cardBg = "mantle";
        infoBg = "surface0";
      };
    }
  );

  sops.templates."pi-models.json" = {
    path = "${piDir}/models.json";
    mode = "0600";
    # Both providers differ only in baseUrl; everything else (api, headers,
    # compat, model catalog) is shared.
    content = builtins.toJSON {
      providers = builtins.mapAttrs (_: p: {
        inherit (p) name baseUrl;
        apiKey = config.sops.placeholder.mimir_api_key;
        api = "openai-completions";
        headers."x-bf-passthrough-extra-params" = "true";
        # vLLM behind the gateway: no `developer` role.
        compat.supportsDeveloperRole = false;
        models = mimirModels;
      }) {
        cubbit = {
          name = "Cubbit Mimir";
          baseUrl = config.sops.placeholder.mimir_base_url;
        };
        cubbit-headroom = {
          name = "Cubbit Mimir (Headroom)";
          baseUrl = "http://127.0.0.1:8788/v1";
        };
      };
    };
  };

  # Same PATH gap as opencode.nix: pi lands in the home-manager profile
  # (/etc/profiles/per-user/$USER/bin), which is not on the PATH of apps
  # launched by launchd — notably Open Design's daemon, so it reports Pi as
  # unavailable. ~/.local/bin is on that PATH.
  # OPEN_DESIGN_AGENT_BINS: pi
  home.activation.pi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${piDir}" "${localBin}"
    $DRY_RUN_CMD ln -sfn "${pkgs.pi-coding-agent}/bin/pi" "${localBin}/pi"

    # Seed settings.json once. pi owns this file at runtime and rewrites it on
    # launch, so it must stay a plain file outside home.file (see the header).
    # A pre-existing symlink from the old mkOutOfStoreSymlink wiring is replaced
    # by a copy; the repo stays the source of truth for defaults.
    if [ ! -f "${piDir}/settings.json" ] || [ -L "${piDir}/settings.json" ]; then
      $DRY_RUN_CMD cp "${repoRoot}/.pi/agent/settings.json" "${piDir}/settings.json"
      $DRY_RUN_CMD chmod 644 "${piDir}/settings.json"
    fi

    # Drop the Anthropic credential so Opus is never reachable from pi.
    auth="${piDir}/auth.json"
    if [ -f "$auth" ] && ${jq} -e 'has("anthropic")' "$auth" >/dev/null; then
      ${jq} 'del(.anthropic)' "$auth" > "$auth.new"
      chmod 600 "$auth.new"
      $DRY_RUN_CMD mv "$auth.new" "$auth"
    fi
  '';
}
