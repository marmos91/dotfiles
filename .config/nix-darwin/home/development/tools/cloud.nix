{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # AWS
    awscli2

    # Kubernetes
    kubernetes-helm
    kubectl
    kubectx

    # Infrastructure as Code
    tilt

    # Data processing
    jq
    yq
  ];
}
