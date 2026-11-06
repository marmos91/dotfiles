{ config, pkgs, lib, hostname, username, ... }:
let
  common = import ./common.nix { inherit pkgs hostname username; };

  # Feeds the `secrets` completion lists; the script itself lives in
  # home/scripts/secrets.nix.
  secretNames = lib.concatStringsSep " " (lib.naturalSort (builtins.attrNames config.sops.secrets));
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historySize = 50000;
    historyFileSize = 50000;
    historyFile = "${config.xdg.dataHome}/bash/history";
    historyControl = [ "ignoredups" "ignorespace" "erasedups" ];

    shellAliases = common.aliases;

    initExtra = ''
      ${common.functions}
      _secrets_completions() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        local prev="''${COMP_WORDS[COMP_CWORD-1]}"
        local secrets="${secretNames}"

        case "$prev" in
          edit|view)
            COMPREPLY=($(compgen -W "$secrets" -- "$cur"))
            ;;
          *)
            COMPREPLY=($(compgen -W "edit view add" -- "$cur"))
            ;;
        esac
      }
      complete -F _secrets_completions secrets
    '';
  };
}
