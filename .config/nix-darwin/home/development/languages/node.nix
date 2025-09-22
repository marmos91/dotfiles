{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      nodejs
      # pnpm is installed via Homebrew
    ];

  home.sessionVariables = { PNPM_HOME = "$HOME/Library/pnpm"; };
}
