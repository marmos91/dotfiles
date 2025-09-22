{ pkgs, ... }: {
  home.packages = with pkgs;
    [
      rustup
      # Rust tools are typically managed via rustup/cargo
    ];
}
