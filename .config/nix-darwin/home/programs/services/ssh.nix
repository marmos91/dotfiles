{ pkgs, lib, isWSL, ... }:
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

    # On native Linux keep 1Password as the SSH agent. On macOS rely on the
    # native launchd ssh-agent (SSH_AUTH_SOCK set automatically) plus
    # Keychain-stored passphrases; no IdentityAgent override needed. Under
    # WSL2 there's no forwarded agent socket — 1Password is reached via
    # ssh.exe/WSL interop instead (git only; see programs/git/config.nix).
    extraConfig = lib.optionalString (!isDarwin && !isWSL) ''
      Host *
        IdentityAgent "~/.1password/agent.sock"
    '';
  };
}
