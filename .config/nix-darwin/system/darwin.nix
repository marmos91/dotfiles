{ pkgs, lib, username, ... }:
{
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      # Performance optimizations
      max-jobs = 8;
      cores = 0;
      auto-optimise-on-install = true;

      # Security
      restrict-eval = true;
      trusted-users = [
        "@admin"
        username
      ];
      allowed-users = [ "@wheel" ];

      # Cache settings
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];

      # Build settings
      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;

      # Garbage collection thresholds
      min-free = lib.mkDefault (1000 * 1000 * 1000); # 1GB
      max-free = lib.mkDefault (3000 * 1000 * 1000); # 3GB
    };
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
