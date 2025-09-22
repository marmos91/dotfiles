{ pkgs, ... }: {
  home.packages = with pkgs; [
    git-lfs
    gh # GitHub CLI
    hub # Git wrapper
    lazygit # Terminal UI for git
  ];
}
