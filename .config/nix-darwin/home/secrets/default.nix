{ config, pkgs, lib, homeDirectory, ... }:
{
  # Install sops and age tools for managing secrets
  home.packages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

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
    };
  };
}
