{ ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
      enter_accept = true;  # Execute immediately on Enter
    };
  };
}
