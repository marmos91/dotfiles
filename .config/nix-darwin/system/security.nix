{ ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  # Default-off ALF is the standard first lateral-movement step against a laptop
  # that holds sops-decrypted credentials and runs Docker/netbird/Tailscale.
  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    # netbird/Tailscale/Docker are Developer ID signed, not Apple signed.
    allowSignedApp = true;
  };

  # Touch ID for sudo does not gate an unattended, already-unlocked session.
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0;
  };
}
