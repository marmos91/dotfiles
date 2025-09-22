{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Automation
    ansible

    # Certificates
    certbot

    # Development utilities
    claude-code
    tmuxinator
    reattach-to-user-namespace
  ];
}
