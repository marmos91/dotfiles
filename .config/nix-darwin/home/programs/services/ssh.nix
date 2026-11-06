{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [ "~/.ssh/config.d/*" ];

    settings = {
      # Everything ssh already defaults to is left out on purpose; only the
      # agent decision and the macOS keychain lookup are real here.
      "*" = {
        AddKeysToAgent = "yes";
      } // lib.optionalAttrs isDarwin {
        UseKeychain = "yes";
      };
    };

    # On Linux keep 1Password as the SSH agent. On macOS rely on the
    # native launchd ssh-agent (SSH_AUTH_SOCK set automatically) plus
    # Keychain-stored passphrases; no IdentityAgent override needed.
    extraConfig = lib.optionalString (!isDarwin) ''
      Host *
        IdentityAgent "~/.1password/agent.sock"
    '';
  };
}
