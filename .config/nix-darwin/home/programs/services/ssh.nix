{ pkgs, lib, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [ "~/.ssh/config.d/*" ];

    settings = {
      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        Compression = false;
        AddKeysToAgent = "yes";
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
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
