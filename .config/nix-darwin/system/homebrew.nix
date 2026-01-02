{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs.no_quarantine = true;

    taps = [
      "nikitabobko/tap"
    ];

    brews = [ "mas" ];

    casks = [
      "1password"
      "aerospace"
      "aldente"
      "betterdisplay"
      "cyberduck"
      "cleanmymac"
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
