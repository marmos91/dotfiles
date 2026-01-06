{ pkgs, lib, username, homeDirectory, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.11";

    sessionPath = [
      "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
      "$HOME/.local/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";

      # Development
      DOTFILES_DIR = "$HOME/.dotfiles";
      OBSIDIAN_VAULTS_DIR = "$HOME/vaults";
      GPG_TTY = "$(tty)";
      GITHUB_USERNAME = "marmos91";
      BACKUP_VOLUME = "/Volumes/BackupMarco";

      # Language-specific
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
      PNPM_HOME = if isDarwin then "$HOME/Library/pnpm" else "$HOME/.local/share/pnpm";

      # Appearance
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
    };
  };

  programs.home-manager.enable = true;
}
