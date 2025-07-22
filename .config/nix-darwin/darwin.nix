{ self, pkgs, ... }: {
  users.users.marmos91.home = "/Users/marmos91";
  users.users.marmos91.shell = pkgs.zsh;

  # Nix configuration
  nix.settings = {
    experimental-features = "nix-command flakes";
    # Performance: Enable parallel building
    max-jobs = 8;
    # Performance: Enable binary cache
    substituters =
      [ "https://cache.nixos.org/" "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Enable alternative shell support in nix-darwin.
  programs.zsh.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  system.primaryUser = "marmos91";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment = {
    # List packages installed in system profile. To search by name, run $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [ coreutils curl vim git gnused gawk ];

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
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs.no_quarantine = true;

    taps = [ "nikitabobko/tap" "FelixKratz/formulae" "netbirdio/tap" ];
    brews = [ "borders" "helm" "ibazel" "netbird" "pnpm" ];
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
      "epic-games"
      "ghostty"
      "gpg-suite"
      "handbrake"
      "ibkr"
      "istat-menus"
      "mos"
      "netbird-ui"
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
