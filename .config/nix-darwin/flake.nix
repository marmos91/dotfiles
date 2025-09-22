{
  description = "Marmos91 Darwin Configuration";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";  # Use GitHub URL for consistency
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";  # This will track master/main
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    inputs@{ self, nix-darwin, nixpkgs, claude-code, home-manager, determinate, ... }: {
      nixpkgs.config.allowUnfree = true;

      darwinConfigurations = {
        amaterasu = nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
          modules = [
            inputs.determinate.darwinModules.default
            ./darwin.nix
            home-manager.darwinModules.home-manager
            ({...}: {
              nix.enable = false;
              determinate-nix.customSettings = {
                flake-registry = "/etc/nix/flake-registry.json";
              };
            })
            {
              nixpkgs.overlays = [ claude-code.overlays.default ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.users.marmos91 = import ./home.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
        };
      };
    };
}
