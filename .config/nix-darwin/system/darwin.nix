{ pkgs, username, ... }:
{
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

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
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment = {
    systemPackages = with pkgs; [
      coreutils
      curl
      vim
      git
      gnused
      gawk
    ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
}
