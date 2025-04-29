{ self, pkgs, ... }: {
  users.users.marmos91.home = "/Users/marmos91";
  users.users.marmos91.shell = pkgs.fish;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment = {
    # List packages installed in system profile. To search by name, run $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [ coreutils curl vim ];

    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.fira-code pkgs.nerd-fonts.meslo-lg ];

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    finder.FXPreferredViewStyle = "clmv";
    finder.ShowStatusBar = true;

    dock.autohide = true;
    dock.orientation = "left";
    dock.persistent-apps = [
      "/Applications/Arc.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Messages.app"
      "/Applications/WhatsApp.app"
      "/Applications/Telegram.app"
      "/Applications/Slack.app"
      "/Applications/Ghostty.app"
      "/Applications/Spotify.app"
      "/System/Applications/System Settings.app"
    ];
    dock.persistent-others = [ "/Users/marmos91/Downloads" "/Applications" ];
    dock.mru-spaces = false;
    dock.showhidden = true;
    dock.show-recents = false;
    # Icon size
    dock.tilesize = 42;

    NSGlobalDomain.AppleShowAllExtensions = true;

    # Make keyboard usable
    NSGlobalDomain.InitialKeyRepeat = 10;
    NSGlobalDomain.KeyRepeat = 1;

    # Expand save panel by default
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
    NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

    # Save on computer, not iCloud
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;

    # Disable smart quotes as they’re annoying when typing code
    NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;

    # Disable automatic period substitution as it’s annoying when typing code
    NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;

    # Disable automatic capitalization as it’s annoying when typing code
    NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;

    # Disable smart dashes as they’re annoying when typing code
    NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;

    # Disable auto-correct
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;

    # Configure tracking speed (0 to 3)
    NSGlobalDomain."com.apple.trackpad.scaling" = 3.0;

    menuExtraClock.Show24Hour = true;

    # Disable click to show desktop (false means "Only in Stage Manager")
    WindowManager.EnableStandardClickToShowDesktop = false;

    # Trackpad
    trackpad.Clicking = true;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    caskArgs.no_quarantine = true;

    taps = [ "nikitabobko/tap" "FelixKratz/formulae" "netbirdio/tap" ];
    brews = [ "borders" "helm" "ibazel" "netbird" "ansible" "k9s" ];
    casks = [
      "1password"
      "adobe-creative-cloud"
      "aerospace"
      "aldente"
      "arc"
      "bartender"
      "bettertouchtool"
      "cleanmymac"
      "cursor"
      "dbeaver-community"
      "docker"
      "dropbox"
      "ghostty"
      "gpg-suite"
      "handbrake"
      "ibkr"
      "istat-menus"
      "netbird-ui"
      "nordvpn"
      "obs"
      "obsidian"
      "raspberry-pi-imager"
      "raycast"
      "slack"
      "spotify"
      "steam"
      "telegram"
      "the-unarchiver"
      "transmission"
      "tripmode"
      "vlc"
      "wezterm"
      "whatsapp"
      "zoom"
    ];
    masApps = {
      LanScan = 472226235;
      WireGuard = 1451685025;
    };
  };
}
