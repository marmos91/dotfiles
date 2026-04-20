{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    taps = [
      "nikitabobko/tap"
      "marmos91/tap"
      "netbirdio/tap"
    ];

    brews = [
      "libimobiledevice"
      "mas"
      "marmos91/tap/dfs"
      "marmos91/tap/dfsctl"
      "netbirdio/tap/netbird"
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
      WireGuard = 1451685025;
      Xcode = 497799835;
    };
  };
}
