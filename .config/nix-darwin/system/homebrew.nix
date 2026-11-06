{ ... }:
{
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
    # Homebrew 6.0 refuses to load formulae/casks from untrusted third-party
    # taps. `trusted = true` emits `trusted: true` into the Brewfile and
    # `brew bundle` applies it before loading anything — no hand-written
    # trust.json needed.
    taps = [
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
      {
        name = "netbirdio/tap";
        trusted = true;
      }
      {
        name = "cubbit/tap";
        trusted = true;
      }
    ];

    brews = [
      "libimobiledevice"
      "mas"
      "netbirdio/tap/netbird"
      "openfortivpn"
      "rclone"
      "rtk"
    ];

    # Some of these are pinned to the Dock in preferences.nix (persistent-apps).
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
      "cubbit/tap/dfs"
      "cubbit/tap/dfsctl"
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
