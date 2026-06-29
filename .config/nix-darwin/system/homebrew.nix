{ lib, ... }:
let
  user = "marmos91";

  # Homebrew 6.0 refuses to load formulae/casks from untrusted third-party
  # taps. Trust is a consumer-side allowlist in ~/.homebrew/trust.json — there
  # is no publisher-side toggle. Keep this list in sync with `homebrew.taps`.
  trustedTaps = [
    "nikitabobko/tap"
    "marmos91/tap"
    "netbirdio/tap"
  ];
  trustJson = builtins.toJSON { trustedtaps = trustedTaps; };
in
{
  # `brew bundle` runs as part of system activation, BEFORE home-manager, so the
  # trust file must be seeded here (as root, into the user's home) or the bundle
  # step fails. mkBefore guarantees this runs before `brew bundle`.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    mkdir -p /Users/${user}/.homebrew
    printf '%s' '${trustJson}' > /Users/${user}/.homebrew/trust.json
    chown ${user}:staff /Users/${user}/.homebrew /Users/${user}/.homebrew/trust.json
  '';

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    taps = trustedTaps;

    brews = [
      "libimobiledevice"
      "mas"
      "marmos91/tap/dfs"
      "marmos91/tap/dfsctl"
      "netbirdio/tap/netbird"
      "rclone"
    ];

    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "aldente"
      "bartender"
      "betterdisplay"
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
