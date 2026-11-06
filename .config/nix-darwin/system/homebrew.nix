{ lib, username, ... }:
let
  user = username;

  # Homebrew 6.0 refuses to load formulae/casks from untrusted third-party
  # taps. Trust is a consumer-side allowlist in ~/.homebrew/trust.json — there
  # is no publisher-side toggle. Keep this list in sync with `homebrew.taps`.
  trustedTaps = [
    "cubbit/tap"
    "nikitabobko/tap"
    "marmos91/tap"
    "netbirdio/tap"
  ];
  trustJson = builtins.toJSON { trustedtaps = trustedTaps; };
in
{
  # `brew bundle` runs as part of system activation, BEFORE home-manager, so the
  # trust file must be seeded here or the bundle step fails. mkBefore
  # guarantees this runs before `brew bundle`.
  #
  # Activation runs as root, but ~/.homebrew is user-controlled: a root write
  # can be steered through a symlink (`ln -s /etc ~/.homebrew`, or trust.json
  # pointing at a directory) and any check-then-write is racy. So drop to the
  # user, the same way nix-darwin runs `brew bundle`: the write can only land
  # where the user could already write, and needs no chown.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    sudo --user=${user} --set-home /bin/sh -c \
      'umask 022 && mkdir -p "$HOME/.homebrew" && printf %s "$1" > "$HOME/.homebrew/trust.json"' \
      sh '${trustJson}' \
      || { echo "error: could not seed ~/.homebrew/trust.json as ${user}" >&2; exit 1; }
  '';

  homebrew = {
    enable = true;
    onActivation = {
      # Declarative: removes anything not listed below.
      cleanup = "uninstall";
      # Non-deterministic third-party upgrades don't belong in activation — they
      # make `rebuild` slow, interactive (sudo prompts) and able to fail on
      # unrelated brew errors. Run `brew update && brew upgrade` on your own time.
      autoUpdate = false;
      upgrade = false;
    };
    taps = trustedTaps;

    brews = [
      "libimobiledevice"
      "cubbit/tap/dfs"
      "cubbit/tap/dfsctl"
      "mas"
      "netbirdio/tap/netbird"
      "openfortivpn"
      "rclone"
      "rtk"
    ];

    casks = [
      "1password"
      "1password-cli"
      # Must be tap-qualified. `brew bundle --cleanup` rewrites the trust store
      # from the Brewfile, and an unqualified name resolves to the core cask —
      # so nikitabobko/tap/aerospace was left untrusted and `brew cleanup`
      # exited 1 on every activation.
      "nikitabobko/tap/aerospace"
      "aldente"
      "bartender"
      "betterdisplay"
      "bettertouchtool"
      "boosteroid"
      "claude"
      "cleanmymac"
      "cursor"
      "cyberduck"
      "discord"
      "dbeaver-community"
      "docker-desktop"
      "dropbox"
      "epic-games"
      "ghostty"
      "google-chrome"
      "gpg-suite"
      "handbrake-app"
      "istat-menus"
      "kicad"
      "microsoft-teams"
      "netbirdio/tap/netbird-ui"
      "nordvpn"
      "notion"
      "obs"
      "obsidian"
      "open-design"
      "raycast"
      "slack"
      "spotify"
      "steam"
      "tailscale-app"
      "telegram"
      "the-unarchiver"
      "transmission"
      "tripmode"
      "utm"
      "vlc"
      "whatsapp"
      "zen"
      "zoom"
    ];

    masApps = {
      LanScan = 472226235;
      VMwareRemoteConsole = 1230249825;
      WireGuard = 1451685025;
      Xcode = 497799835;
    };
  };
}
