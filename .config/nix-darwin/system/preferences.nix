{ ... }: {
  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    defaults = {
      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXPreferredViewStyle = "clmv";
        ShowStatusBar = true;
      };

      dock = {
        autohide = true;
        orientation = "left";
        persistent-apps = [
          "/Applications/Zen.app"
          "/System/Applications/Mail.app"
          "/Applications/WhatsApp.app"
          "/Applications/Telegram.app"
          "/Applications/Slack.app"
          "/Applications/Ghostty.app"
          "/Applications/Spotify.app"
          "/System/Applications/System Settings.app"
        ];
        persistent-others = [ "/Users/marmos91/Downloads" "/Applications" ];
        mru-spaces = false;
        showhidden = true;
        show-recents = false;
        tilesize = 42;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        "com.apple.trackpad.scaling" = 3.0;
      };

      menuExtraClock.Show24Hour = true;
      WindowManager.EnableStandardClickToShowDesktop = false;
      trackpad.Clicking = true;
    };
  };
}
