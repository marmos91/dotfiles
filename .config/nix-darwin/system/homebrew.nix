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
      "betterdisplay"
      "boosteroid"
      "claude"
      "cyberduck"
      "cleanmymac"
      "crossover"
      "cursor"
      "dbeaver-community"
      "docker-desktop"
      "dropbox"
      "epic-games"
      "ghostty"
      "gpg-suite"
      "google-chrome"
      "handbrake-app"
      "bartender"
      "istat-menus"
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
