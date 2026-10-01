# Obsidian vault wiring: theme + community plugins, fetched from pinned GitHub
# release assets rather than the community store (which has no declarative API).
#
# Scope and ownership — the whole point of this module:
#
#   Owned here (home.file, so HM can garbage-collect it on removal):
#     <vault>/.obsidian/themes/Catppuccin/{theme.css,manifest.json}
#     <vault>/.obsidian/plugins/<id>/{main.js,manifest.json,styles.css}
#
#   Deliberately NOT owned — these are the app's runtime state, and HM cannot
#   express them:
#     community-plugins.json    enabled-plugin set; written by Obsidian whenever
#                               a plugin is toggled. A home.file here would be
#                               clobbered on the first toggle.
#     plugins/<id>/data.json    per-plugin settings, written by the plugin.
#                               obsidian.nix merges one setting into it (see the
#                               activation block below) but never owns the file.
#     workspace.json            open panes, cursor positions.
#
# Enabling is therefore a one-time GUI step, and Obsidian splits it across two
# switches in two different stores:
#
#   1. Settings > Community plugins > Turn on community plugins
#      This is "restricted mode", stored in Chromium localStorage under
#      `enable-plugin-<appId>` — not in any JSON file, so it cannot be preseeded.
#   2. Toggle each plugin on.
#
# Once (1) is done, the built-in CLI (Settings > General > Command line
# interface) can do (2) without the GUI:
#   obsidian plugin:enable id=obsidian-git filter=community   # x4
#
# Neither step is expressible as Nix, and that is a property of Obsidian, not an
# unfinished edge here.
#
# Version pins are release tags, not floating branches: main.js is an arbitrary
# bundle and a silently-updated one is a supply-chain risk. Bump a `pin` and
# re-run `nix store prefetch-file --hash-type sha256 <url>` for the new assets.
#
# `catppuccin/obsidian` is not a port in the catppuccin/nix flake (which covers
# bat/btop/delta/fzf/k9s/lazygit/starship/tmux/zsh only), so `autoEnable` in
# catppuccin.nix cannot reach it and it is wired by hand below.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  vault = "${config.home.homeDirectory}/Projects/dittofs/docs";
  obsidianDir = "${vault}/.obsidian";

  # Fetch one release asset and pin it by hash. `fetchurl`, not `fetchzip`:
  # these are loose files (main.js, theme.css), not archives, so there is no
  # root directory to strip.
  asset =
    {
      name,
      url,
      hash,
    }:
    pkgs.fetchurl { inherit name url hash; };

  # One community plugin. `files` are the release assets Obsidian loads; a
  # plugin that ships none (e.g. no styles.css) simply omits it. `id` must match
  # the `id` in the plugin's manifest.json, because that is the directory name
  # Obsidian resolves and the name `plugin:enable` takes.
  plugin =
    {
      id,
      repo,
      pin,
      mainHash,
      manifestHash,
      stylesHash ? null,
    }:
    {
      dir = "${obsidianDir}/plugins/${id}";
      main = asset {
        name = "${id}-main.js";
        url = "https://github.com/${repo}/releases/download/${pin}/main.js";
        hash = mainHash;
      };
      manifest = asset {
        name = "${id}-manifest.json";
        url = "https://github.com/${repo}/releases/download/${pin}/manifest.json";
        hash = manifestHash;
      };
      styles =
        if stylesHash == null then
          null
        else
          asset {
            name = "${id}-styles.css";
            url = "https://github.com/${repo}/releases/download/${pin}/styles.css";
            hash = stylesHash;
          };
    };

  plugins = [
    # Git — commit/sync from inside the vault. Works on any git repo, including
    # this one; it drives the system `git`, so the vault's own remote and
    # identity apply. No credentials of its own.
    (plugin {
      id = "obsidian-git";
      repo = "Vinzent03/obsidian-git";
      pin = "2.40.0";
      mainHash = "sha256-bxmPFAvjklTEEMIZmMG9hvmgd61BVgQ1Y4Ll3Fg24aE=";
      manifestHash = "sha256-yfDUnCCUxHUbl+OVAVtJdhZRlEw3HLpnu/akYXDyy5E=";
      stylesHash = "sha256-9auT9NW03RvR5XeGTFx5CH9639RIrDRuBInlhHzmki0=";
    })

    # Local REST API with MCP — the bridge the MCP client below talks to. Ships
    # its own MCP server on the same listener at /mcp/, so no second process is
    # needed. It generates its own apiKey on first load and persists it to
    # data.json; the MCP client reads that key back out, so nothing has to be
    # seeded or copied. The one setting it does need is merged in below.
    (plugin {
      id = "obsidian-local-rest-api";
      repo = "coddingtonbear/obsidian-local-rest-api";
      pin = "5.2.0";
      mainHash = "sha256-cD+9DJNndysxFm+JgNh/cHFlGA6mfLOqmFmR9Gdsv9M=";
      manifestHash = "sha256-8Ch0j8qFoZULniLj0ePwew4sas51mH/DaHMdMDuuw6A=";
      stylesHash = "sha256-GZVt6vTRQUI4H4H9+SyugkH9CqCKGjpUZLDQB7rhkk0=";
    })

    # Review Comments — Notion-style review comments stored as CriticMarkup
    # inline in the .md file, e.g. {==text==}{>>author|date: comment<<}. Chosen
    # over the sidecar-JSON alternatives (Marginalia, Sidemark, Redline) because
    # the comment ends up in the document text, so pi/Claude read it with no
    # export step and no extra tool. The {>> <<} form is a de-facto convention
    # other Markdown tooling already understands.
    (plugin {
      id = "review-comments";
      repo = "shotashirai1719/obsidian-review-comments";
      pin = "2.0.0";
      mainHash = "sha256-eAlJMJb8ZrAUmirFXPKJuxpRd9ZUYKZNpESmtsUPQxQ=";
      manifestHash = "sha256-+vFCuj+tZWSPgl5HcGOUZbd2U1rYHrGq9sDokK2O3X8=";
      stylesHash = "sha256-16SgsNcQp7lwoTpifRXEWOWQ6r3yOmad1XDHIfuy0w0=";
    })

    # Typewriter Mode — keeps the active line centred and dims the rest of the
    # paragraph. For reading long docs this is the effective one; the bionic /
    # speed-reading plugins (Fastread et al.) are unmaintained single-author
    # bundles, and this is the maintained 105k-download equivalent.
    (plugin {
      id = "typewriter-mode";
      repo = "davisriedel/obsidian-typewriter-mode";
      pin = "1.5.0";
      mainHash = "sha256-Ey6ztqNXIoS1f4QTJEfqhe2kMUZ4e5xrkY24nx4eGNo=";
      manifestHash = "sha256-3aQTvfHZIcR2+yeKMszfCDJBOD/V2UDkJ7/S3UxwrVQ=";
      stylesHash = "sha256-tVRyxu2B8DM2Vrb3Q/eibbZ+sJ9UG4JjqA+NOe1Lf+8=";
    })
  ];

  catppuccinTheme = {
    dir = "${obsidianDir}/themes/Catppuccin";
    # Pinned to the v2.0.4 tag. The theme's own manifest version (0.4.14) trails
    # the repo tag, which is normal for this repo — Obsidian reads the manifest,
    # not the tag.
    css = asset {
      name = "catppuccin-theme.css";
      url = "https://raw.githubusercontent.com/catppuccin/obsidian/v2.0.4/theme.css";
      hash = "sha256-qqD0qvBaZ189oCkfaZ72F6jpiZJi95USR2sapEo2vzs=";
    };
    manifest = asset {
      name = "catppuccin-manifest.json";
      url = "https://raw.githubusercontent.com/catppuccin/obsidian/v2.0.4/manifest.json";
      hash = "sha256-6N5euU6sVnr1BliN1YjMmwg0lbT3MG1TPD55Qxr1GGI=";
    };
  };
in
{
  # The vault directory itself, then each plugin/theme file. home.file entries
  # are read-only store symlinks; Obsidian only reads these paths (it writes
  # data.json alongside them, which is why each plugin gets a directory rather
  # than a single symlinked file).
  home.file = {
    "${catppuccinTheme.dir}/theme.css".source = catppuccinTheme.css;
    "${catppuccinTheme.dir}/manifest.json".source = catppuccinTheme.manifest;
  }
  // builtins.listToAttrs (
    lib.concatMap (p: [
      {
        name = "${p.dir}/main.js";
        value.source = p.main;
      }
      {
        name = "${p.dir}/manifest.json";
        value.source = p.manifest;
      }
    ] ++ lib.optional (p.styles != null) {
      name = "${p.dir}/styles.css";
      value.source = p.styles;
    }) plugins
  );

  # Force the Local REST API plugin's plain-HTTP listener on (127.0.0.1:27123).
  # The MCP client above hardcodes that URL — the default HTTPS port uses a
  # self-signed certificate each client would have to trust separately — so this
  # is a precondition of the bridge, not a preference, and it is re-asserted on
  # every rebuild.
  #
  # Merged, never overwritten: the plugin owns this file, and the apiKey inside
  # it is what the MCP client reads back at connect time, so it has to survive.
  # Only enableInsecureServer is ours. Runs before the plugin loads because
  # Obsidian reads data.json at startup; if the app is already running, the
  # setting applies on next start.
  home.activation.obsidian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    data="${obsidianDir}/plugins/obsidian-local-rest-api/data.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$data")"

    if [ -f "$data" ]; then
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.enableInsecureServer = true' "$data" > "$data.new"
    else
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq -n '{enableInsecureServer: true}' > "$data.new"
    fi
    $DRY_RUN_CMD chmod 600 "$data.new"
    $DRY_RUN_CMD mv "$data.new" "$data"
  '';
}
