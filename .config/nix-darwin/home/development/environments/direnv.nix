{ ... }: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;

    config = {
      # Global direnv settings
      whitelist = { prefix = [ "$HOME/Projects" ]; };
    };
  };
}
