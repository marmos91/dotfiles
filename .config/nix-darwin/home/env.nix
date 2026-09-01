{ pkgs, lib, username, homeDirectory, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
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

      # starship warns whenever a fat directory (/nix/store) blows scan_timeout;
      # the bail-out is intended, so only the log is noise.
      STARSHIP_LOG = "error";
    } // lib.optionalAttrs (!isDarwin) {
      # 1Password SSH agent (Linux only — macOS uses the native launchd ssh-agent
      # so keys in ~/.ssh work with Keychain-stored passphrases and don't
      # require unlocking 1Password for every SSH op).
      SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
    } // {

      # Development
      DOTFILES_DIR = "$HOME/.dotfiles";
      OBSIDIAN_VAULTS_DIR = "$HOME/vaults";
      GPG_TTY = "$(tty)";
      GITHUB_USERNAME = "marmos91";
      # GitHub MCP server auth — derived from the gh CLI keyring at shell init
      # (no secret stored in the repo). Empty if gh is not logged in.
      GITHUB_PERSONAL_ACCESS_TOKEN = "$(gh auth token 2>/dev/null)";
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
