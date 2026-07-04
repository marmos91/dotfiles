{ ... }: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Atuin owns Ctrl-R (history search); disable fzf's history widget to avoid the conflict.
    historyWidget.command = "";
    defaultOptions =
      [ "--height 40%" "--border" "--bind 'ctrl-j:down,ctrl-k:up'" ];
  };
}
