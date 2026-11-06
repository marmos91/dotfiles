{ pkgs, username, ... }:
{
  # Not users.knownUsers, so nix-darwin never manages the account itself; but
  # home-manager's darwin module reads `home` for home.homeDirectory. `shell`
  # is left out: it only applies to managed users (zsh is the macOS default
  # and programs.zsh.enable already installs it).
  users.users.${username}.home = "/Users/${username}";

  # Nix configuration.
  #
  # The determinate module forces `nix.enable = false`, so nix-darwin's
  # `nix.settings` is never written anywhere. Custom nix.conf settings go
  # through `determinateNix.customSettings`, daemon behaviour through
  # `determinateNix.determinateNixd`. Determinate owns experimental-features,
  # max-jobs, sandbox and the cache keys — don't restate them here.
  determinateNix = {
    # `extra-*` appends; plain `substituters` would drop Determinate's own.
    customSettings = {
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
      trusted-users = [
        "root"
        "@admin"
        username
      ];
    };

    # Background GC. Replaces the min-free/max-free thresholds that never applied.
    determinateNixd.garbageCollector.strategy = "automatic";
  };

  system.stateVersion = 5;
  system.primaryUser = username;

  environment = {
    # Kept for the root/non-interactive context: /run/current-system/sw/bin is
    # not created from home-manager, and activation runs there. Everything the
    # user needs comes from home.packages or a `${pkgs.x}/bin/y` store path.
    systemPackages = with pkgs; [
      coreutils
      curl
    ];
    systemPath = [ "/opt/homebrew/bin" ];
  };
}
