{ ... }: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions =
      [ "--height 40%" "--border" "--bind 'ctrl-j:down,ctrl-k:up'" ];
  };
}
