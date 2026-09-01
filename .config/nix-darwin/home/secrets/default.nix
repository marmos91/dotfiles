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
}
