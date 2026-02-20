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
    ];

    brews = [
      "mas"
      "marmos91/tap/dfs"
      "marmos91/tap/dfsctl"
    ];

    casks = [
      "1password"
      "1password-cli"
      "aerospace"
      "aldente"
      "betterdisplay"
      "boosteroid"
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
      "jordanbaird-ice@beta"
      "istat-menus"
      "microsoft-teams"
      "nordvpn"
      "obs"
      "obsidian"
      "raycast"
      "slack"
      "spotify"
      "steam"
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
    };
  };
}
