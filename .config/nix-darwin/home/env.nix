{ pkgs, lib, username, homeDirectory, isWSL, ... }:
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
    } // lib.optionalAttrs (!isDarwin && !isWSL) {
      # 1Password SSH agent (native Linux desktop app only — macOS uses the
      # native launchd ssh-agent, and under WSL2 1Password's agent runs on
      # the Windows host instead, reached via ssh.exe/WSL interop rather
      # than a forwarded Unix socket; see home/programs/git/config.nix).
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
