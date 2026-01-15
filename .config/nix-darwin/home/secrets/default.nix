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
    };
  };
}
