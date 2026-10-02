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
# Two settings in that seed are load-bearing for Mimir and should not be
# "simplified" back to the defaults:
#
#   compaction.modelOverrides["cubbit/vllm/mimir"].reserveTokens = 131072
#     The base reserveTokens stays at pi's default 16384, which is correct for
#     ordinary models, and the Mimir entries are overridden because the value
#     has to be the model's maxTokens. The override key is exactly
#     `${model.provider}/${model.id}` (settings-manager.js), and pi reports
#     the model id as "vllm/mimir", so the key is the three-segment
#     "cubbit/vllm/mimir" — not "cubbit/vllm".
#     Leaving the default 16384 sets pi's native compaction threshold at
#     contextWindow - 16384 = 901120 tokens. That is not past the server's
#     ~1,048,561-input limit, but it means the one summarization request that
#     matters is a ~900k-token prompt whose output is simultaneously capped
#     at 0.8 * 16384 = ~13k tokens (compaction.js). Both halves are wrong:
#     measured TTFT is already 29.8s at a 514,309-token prompt, so ~900k is
#     far slower, and 13k cannot faithfully summarize 900k tokens. Setting it
#     to the model's maxTokens fires compaction at 786432 and gives the
#     summarizer a ~105k-token budget. Pi's docstring for the setting says it
#     "reserves room for the LLM's response", and for a reasoning model that
#     is maxTokens, not 16k.
#     cubbit/mimir-small keeps the default shape with its own 32768 maxTokens
#     because a 131072 reserve on a 229376 window would leave it almost no
#     working context.
#
#   observational-memory.compactAfterTokensMode = "ratio"
#     The extension defaults to "calibrated", which compacts after a fixed
#     81,000 source-entry tokens regardless of window size — fine for the
#     ~128K-200K models it was tuned for, but it throws away ~87% of a 1M
#     window. Ratio mode scales with contextWindow and is the setting upstream
#     documents for exactly this large-context case. This extension also owns
#     compaction outright: all 1334 compaction entries in the local session
#     logs are fromHook, i.e. its session_before_compact handler returns the
#     summary and pi's native summarizer never runs, so its thresholds are the
#     ones that matter.
#
#   observational-memory.compactAfterTokensRatio = 0.9
#     Measured, not guessed. A 5-needle NIAH sweep (exact-match scoring) held
#     5/5 recall at every size from 48k to 1,040,000 prompt tokens, with no
#     degenerate loop in any of 26 runs; crossing the server cap at 1,070,000
#     returns the 400 "maximum context length is 1048576 tokens", which pi-ai's
#     OVERFLOW_PATTERNS matches, so overflow still takes pi's normal
#     compact-and-retry path instead of hanging.
#     Any ratio above 0.857 stops binding: pi's own reserveTokens threshold
#     (917504 - 131072 = 786432; 786432/917504 = 0.857) fires first. 0.9
#     therefore collapses the two competing thresholds into one at 786432,
#     reclaiming ~163k tokens of working context versus the previous 0.68
#     (623903) while leaving pi's 131k output reserve intact.
#     The ratio never protected against the repetition loop anyway: collapses
#     were observed at 60-72k tokens, far below any compaction threshold. That
#     failure is handled by the loop-breaker extension, not by compaction.
#     Caveat: NIAH measures retrieval, not agentic tool-call resistance; it is
#     evidence against gross long-context degradation, not a loop guarantee.
#
# Do NOT add httpIdleTimeoutMs. It reads like a total-request budget, but it is
# a *stall* detector: it becomes undici's headersTimeout and bodyTimeout, both
# of which refresh on every byte received (http-dispatcher.js sets them from
# this one setting; undici/client-h1.js calls this.timeout.refresh() per chunk).
# Mimir's worst measured inter-chunk gap on a 10473-chunk reasoning stream was
# 4.9s against a 300s default, so the default already has ~60x headroom. The
# one slow case that exists is time-to-first-byte -- 155s for a ~900k-token
# prompt -- and that is inside the default too. A larger value only makes a
# real hang take longer to surface.
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

  # Loop breaker: recovers the degenerate reasoning repetition that the
  # DeepSeek-V4-Flash checkpoint behind Mimir hits in long tool-heavy
  # sessions. It cannot be a config fix — mimir's vLLM accepts and ignores
  # thinking_token_budget (probe: budget 2000 -> 3250 reasoning tokens), so
  # only an extension can detect the empty length-stop and retry. pi loads
  # *.ts from this directory directly via jiti, and never writes into it, so
  # a store symlink is fine (unlike settings.json).
  home.file.".pi/agent/extensions/loop-breaker.ts".source =
    config.lib.file.mkOutOfStoreSymlink "${repoRoot}/.pi/agent/extensions/loop-breaker.ts";

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

    # Warn when the live settings.json has drifted from the repo seed. Because
    # pi owns this file at runtime, the seed is only ever applied once (above),
    # so a later seed edit is otherwise silently ignored — which has already
    # happened twice. Compare only the keys the seed declares: pi rewrites
    # lastChangelogVersion on launch, so a whole-file diff would warn on every
    # rebuild until the warning meant nothing. A drifted key does warn.
    # Warn rather than overwrite: "pi install" legitimately adds packages, and
    # clobbering the live file on every rebuild would discard runtime state.
    drifted=""
    for key in $(${jq} -r 'keys[]' "${repoRoot}/.pi/agent/settings.json"); do
      if ! ${jq} -e --arg k "$key" --slurpfile s "${repoRoot}/.pi/agent/settings.json" \
           '.[$k] == $s[0][$k]' "${piDir}/settings.json" >/dev/null 2>&1; then
        drifted="$drifted $key"
      fi
    done
    if [ -n "$drifted" ]; then
      echo "pi: settings.json drifted from the repo seed:$drifted" >&2
      echo "pi: diff ${piDir}/settings.json ${repoRoot}/.pi/agent/settings.json" >&2
      echo "pi: the seed only applies when the live file is missing; reconcile by hand." >&2
    fi
  '';
}
