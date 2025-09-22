{ pkgs, ... }: {
  home.packages = with pkgs; [
    # AWS
    awscli2

    # Kubernetes
    kubectl
    kubectx

    # Infrastructure as Code
    tilt

    # Data processing
    jq
    yq
  ];
}
