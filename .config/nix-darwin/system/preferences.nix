{ username, ... }:
{
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
        persistent-others = [
          "/Users/${username}/Downloads"
          "/Applications"
        ];
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

      CustomUserPreferences = {
        "com.apple.controlcenter" = {
          AutoHideMenuBarOption = 0;
        };
        # BetterTouchTool. Only the app-level settings live here — the actual
        # triggers/gestures are a Core Data store in
        # ~/Library/Application Support/BetterTouchTool and can't be expressed
        # declaratively; BTT's own cloud sync restores them.
        "com.hegenberg.BetterTouchTool" = {
          launchOnStartup = true;
          SUAutomaticallyUpdate = true;
          BTTDropboxSyncActive = true;
          BTTSyncCloudProvider = 1;
          BTTRemoteEnabled = false;
        };

        # Make a short press of the power/Touch ID button sleep the Mac
        # instead of showing the shutdown dialog. Long-press still forces shutdown.
        "com.apple.loginwindow" = {
          PowerButtonSleepsSystem = true;
          # Reopen apps/windows after a restart, so an accidental power-button
          # shutdown doesn't throw away the session.
          TALLogoutSavesState = true;
        };
      };
    };
  };
}
