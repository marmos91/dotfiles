{ pkgs, ... }: {
  home.packages = with pkgs; [
    # File management
    fd
    ripgrep
    tree
    stow

    # Text processing
    sd

    # Archives
    zstd

    # Networking
    wget
    wireguard-tools

    # System monitoring
    btop
    watch
    tldr

    # Security
    age
    sshpass
  ];
}
