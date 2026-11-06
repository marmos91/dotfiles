{ config, pkgs, lib, homeDirectory, ... }:
{
  # Install sops and age tools for managing secrets
  home.packages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  # Fix sops-nix LaunchAgent PATH issue on macOS
  # The default LaunchAgent has an empty PATH, which prevents getconf and newfs_hfs from being found
  launchd.agents.sops-nix.config.EnvironmentVariables.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";

  sops = {
    # Residual risk: macOS builds are not sandboxed (`sandbox = false`), so any
    # build can read this key and every secret in secrets.yaml. Mitigation:
    # build untrusted flakes only on a Linux builder/VM; keep the age key off
    # build machines.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      kubeconfig = {
        path = "${homeDirectory}/.kube/config";
        mode = "0600";
      };

      aws_credentials = {
        path = "${homeDirectory}/.aws/credentials";
        mode = "0600";
      };

      aws_config = {
        path = "${homeDirectory}/.aws/config";
        mode = "0600";
      };

      rclone_config = {
        path = "${homeDirectory}/.config/rclone/rclone.conf";
        mode = "0600";
      };

      ssh_hosts_config = {
        path = "${homeDirectory}/.ssh/config.d/hosts";
        mode = "0600";
      };

      mimir_api_key = {
        path = "${homeDirectory}/.config/opencode/mimir-key";
        mode = "0600";
      };

      google_docs_mcp_client_id = {
        path = "${homeDirectory}/.config/google-docs-mcp/client-id";
        mode = "0600";
      };

      google_docs_mcp_client_secret = {
        path = "${homeDirectory}/.config/google-docs-mcp/client-secret";
        mode = "0600";
      };

      # gcal-personal-block: OAuth client (Mimir Cloud GCP project) and the
      # calendar identifiers it syncs. Read by the script at runtime, and by
      # `gcal-setup` for the consent screen.
      gcal_client_id = {
        path = "${homeDirectory}/.config/gcal-personal-block/client-id";
        mode = "0600";
      };

      gcal_client_secret = {
        path = "${homeDirectory}/.config/gcal-personal-block/client-secret";
        mode = "0600";
      };

      gcal_family_cal = {
        path = "${homeDirectory}/.config/gcal-personal-block/family-cal";
        mode = "0600";
      };

      gcal_work_email = {
        path = "${homeDirectory}/.config/gcal-personal-block/work-email";
        mode = "0600";
      };

      # Internal Cubbit endpoints. Not credentials, but they name company
      # infrastructure, so they stay out of the public repo. opencode resolves
      # `{file:...}` in any config value and trims the trailing newline.
      mimir_base_url = {
        path = "${homeDirectory}/.config/opencode/mimir-base-url";
        mode = "0600";
      };

      ds3ctl_config = {
        path = "${homeDirectory}/.config/ds3ctl/config.yaml";
        mode = "0600";
      };

      # Git identities. These are gitconfig fragments pulled in by `includes`
      # in programs/git/config.nix, so the addresses stay out of the public
      # repo. Keeping them here (rather than in nix) means git reads them at
      # runtime — sops values are never available at eval time.
      git_identity = {
        path = "${homeDirectory}/.config/git/identity";
        mode = "0600";
      };

      git_identity_work = {
        path = "${homeDirectory}/.config/git/identity-work";
        mode = "0600";
      };

      # Signer trust list — matched by the commit's email, so it carries the
      # addresses too. Replaces the former home.file entry.
      git_allowed_signers = {
        path = "${homeDirectory}/.config/git/allowed_signers";
        mode = "0600";
      };

    };
  };

  # Fail the rebuild when the age key is missing or loose. Without this, a
  # machine whose key was never created rebuilds "successfully" with zero
  # secrets materialised — the launchd/systemd unit for sops-nix dies quietly
  # and the error only reaches ~/Library/Logs/SopsNix/stderr. Both documented
  # entry points create the key first (install.sh checks for it before the
  # switch; secrets/README.md §1 is the command), so a hard failure here is the
  # documented order. Ordered before sops-nix so nothing is decrypted with a
  # bad key.
  home.activation.sopsAgeKey = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    key="${homeDirectory}/.config/sops/age/keys.txt"
    if [ ! -r "$key" ]; then
      echo "sops: age key $key is missing or unreadable — secrets were NOT decrypted." >&2
      echo "sops: create it per home/secrets/README.md §1 (age-keygen -o), then rerun rebuild." >&2
      exit 1
    fi
    # Activation puts GNU coreutils first on PATH on every platform. -L so a
    # symlinked keys.txt reports the mode of the file it points at.
    mode=$(stat -L -c '%a' "$key")
    if [ "$(( 8#$mode & 077 ))" -ne 0 ]; then
      echo "sops: $key is group/world-readable (mode $mode); expected 0600 or tighter." >&2
      echo "sops: re-run the key step with umask 077 (see README), then: chmod 600 $key" >&2
      exit 1
    fi
  '';
}
