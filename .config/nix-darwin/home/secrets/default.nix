{ config, pkgs, lib, homeDirectory, ... }:
let
  # Every secret is a 0600 file under $HOME; one place to change the mode.
  mk = p: {
    path = "${homeDirectory}/${p}";
    mode = "0600";
  };

  # Top-level keys of the template, so the eval below can hold it to the same
  # key set as `sops.secrets`.
  templateKeys = lib.concatMap (l: let m = builtins.match "([a-z0-9_]+):.*" l; in if m == null then [ ] else m) (
    lib.splitString "\n" (builtins.readFile ./secrets.yaml.template)
  );
in
{
  # Install sops for managing secrets (age lives in home/packages.nix).
  # ssh-to-age stays: secrets/README.md documents it (Option B) as a way to
  # derive the age key from the 1Password-managed SSH key on a new machine.
  home.packages = with pkgs; [
    sops
    ssh-to-age
  ];

  # Darwin-only: the sops-nix LaunchAgent starts with an empty PATH, which
  # leaves getconf/newfs_hfs unresolvable. mkForce (not mkAfter) because the
  # option is a plain str, so this does drop the binPath sops-nix prepends for
  # `sops.age.plugins` — keep it only while that macOS symptom is real.
  launchd.agents.sops-nix.config.EnvironmentVariables.PATH = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin"
  );

  sops = {
    # Residual risk: macOS builds are not sandboxed (`sandbox = false`), so any
    # build can read this key and every secret in secrets.yaml. Mitigation:
    # build untrusted flakes only on a Linux builder/VM; keep the age key off
    # build machines.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      kubeconfig = mk ".kube/config";
      aws_credentials = mk ".aws/credentials";
      aws_config = mk ".aws/config";
      rclone_config = mk ".config/rclone/rclone.conf";
      ssh_hosts_config = mk ".ssh/config.d/hosts";
      mimir_api_key = mk ".config/mimir/api-key";
      google_docs_mcp_client_id = mk ".config/google-docs-mcp/client-id";
      google_docs_mcp_client_secret = mk ".config/google-docs-mcp/client-secret";

      # gcal-personal-block: OAuth client (Mimir Cloud GCP project) and the
      # calendar identifiers it syncs. Read by the script at runtime, and by
      # `gcal-setup` for the consent screen.
      gcal_client_id = mk ".config/gcal-personal-block/client-id";
      gcal_client_secret = mk ".config/gcal-personal-block/client-secret";
      gcal_family_cal = mk ".config/gcal-personal-block/family-cal";
      gcal_work_email = mk ".config/gcal-personal-block/work-email";
      # Internal Cubbit endpoints. Not credentials, but they name company
      # infrastructure, so they stay out of the public repo. Shared by opencode,
      # pi and headroom, so the path names none of them. opencode resolves
      # `{file:...}` in any config value and trims the trailing newline.
      mimir_base_url = mk ".config/mimir/base-url";
      # Both used to live under ~/.config/opencode/. On a machine that had
      # them, remove the old links if they are still there:
      #   rm ~/.config/opencode/mimir-key ~/.config/opencode/mimir-base-url

      # Dropped `ds3ctl_config`: the tool it named is gone (cubbit/dittofs now
      # ships `dfsctl`, which reads ~/.config/dfsctl/config.json and takes the
      # server from --server). sops-nix leaves an already-installed secret in
      # place, so remove it by hand on a machine that had it:
      #   rm ~/.config/ds3ctl/config.yaml ~/.config/sops-nix/secrets/ds3ctl_config

      # Git identities. These are gitconfig fragments pulled in by `includes`
      # in programs/git/config.nix, so the addresses stay out of the public
      # repo. Keeping them here (rather than in nix) means git reads them at
      # runtime — sops values are never available at eval time.
      git_identity = mk ".config/git/identity";
      git_identity_work = mk ".config/git/identity-work";

      # Signer trust list — matched by the commit's email, so it carries the
      # addresses too. Replaces the former home.file entry.
      git_allowed_signers = mk ".config/git/allowed_signers";
    };
  };

  assertions = [
    {
      assertion = lib.naturalSort templateKeys == lib.naturalSort (builtins.attrNames config.sops.secrets);
      message = "home/secrets: secrets.yaml.template keys differ from sops.secrets in default.nix.";
    }
  ];

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
