{ pkgs, ... }: {
  home.packages = with pkgs; [
    python313
    python313Packages.pip
    python313Packages.black # Formatter
    python313Packages.flake8 # Linter
    python313Packages.mypy # Type checker
  ];
}
