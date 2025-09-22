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

  outputs = inputs@{ self, nix-darwin, nixpkgs, claude-code, home-manager
    , determinate, ... }:
    let lib = import ./lib { inherit (nixpkgs) lib; };
    in {
      nixpkgs.config.allowUnfree = true;

      darwinConfigurations = {
        amaterasu = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs lib; };
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
            overlays = [ claude-code.overlays.default ];
          };
          modules = [
            determinate.darwinModules.default
            ./system
            home-manager.darwinModules.home-manager
            {
              nix.enable = false;
              determinate-nix.customSettings = {
                flake-registry = "/etc/nix/flake-registry.json";
              };

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.marmos91 = ./home;
                extraSpecialArgs = { inherit inputs lib; };
              };
            }
          ];
        };
      };
    };
}
