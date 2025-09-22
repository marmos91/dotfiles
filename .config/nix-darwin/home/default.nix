{ config, inputs, lib, ... }: {
  imports = [ ./programs ./development ./packages ./services ];

  home = {
    username = "marmos91";
    homeDirectory = "/Users/marmos91";
    stateVersion = "24.11";

    sessionPath = [
      "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
      "$HOME/.local/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "bat";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";

      # XDG Base Directories
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_CACHE_HOME = "$HOME/.cache";

      # Development
      DOTFILES_DIR = "$HOME/.dotfiles";
      OBSIDIAN_VAULTS_DIR = "$HOME/vaults";
      GPG_TTY = "$(tty)";
      GITHUB_USERNAME = "marmos91";
      BACKUP_VOLUME = "/Volumes/BackupMarco";

      # Language-specific
      GOPATH = "$HOME/go";
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
      PNPM_HOME = "$HOME/Library/pnpm";

      # Appearance
      BAT_THEME = "Catppuccin-mocha";
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
    };
  };

  programs.home-manager.enable = true;
}
