{
  description = "Marmos91 Darwin Configuration";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      claude-code,
      home-manager,
      determinate,
      ...
    }:
    let
      # Configuration variables - change these for a different machine
      username = "marmos91";
      hostname = "amaterasu";
    in
    {
      nixpkgs.config.allowUnfree = true;

      darwinConfigurations = {
        ${hostname} = nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
            overlays = [ claude-code.overlays.default ];
          };
          specialArgs = { inherit username hostname; };
          modules = [
            # Determinate Nix (replaces system nix)
            inputs.determinate.darwinModules.default

            (
              { ... }:
              {
                nix.enable = false; # Disable system nix in favor of determinate
              }
            )

            # System modules
            ./system

            # Home Manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit username hostname; };
                users.${username} = ./home;
              };
            }
          ];
        };
      };
    };
}
