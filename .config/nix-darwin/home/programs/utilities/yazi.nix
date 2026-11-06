# yazi: TUI file manager. Preview/finder deps (7zz, jq, poppler, ffmpeg, fd,
# ripgrep, fzf, zoxide, imagemagick, resvg, chafa) are bundled by the nixpkgs
# wrapper's PATH. Theme comes from the catppuccin flake (catppuccin-yazi port,
# auto-enabled globally in home/catppuccin.nix). The cwd-following shell
# wrapper is home-manager's built-in (`y`, via shellWrapperName).
{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;

    # `y`: home-manager's built-in cwd-following shell wrapper (new default
    # name, adopted explicitly to silence the stateVersion warning).
    shellWrapperName = "y";

    plugins = {
      smart-enter = pkgs.yaziPlugins.smart-enter;
      git = pkgs.yaziPlugins.git;
      compress = pkgs.yaziPlugins.compress;
      lazygit = pkgs.yaziPlugins.lazygit;
      sshfs = pkgs.yaziPlugins.sshfs;
    };

    # Enter on a file opens it; on a (filtering) directory it enters.
    # Mapped onto default `l`/`Enter` so both keys do the smart thing.
    keymap = {
      manager.keymap = [
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory or open the file";
        }
        {
          on = "<Enter>";
          run = "plugin smart-enter";
          desc = "Enter the child directory or open the file";
        }
      ];
    };

    initLua = ''
      require("git"):setup({})
    '';
  };
}
