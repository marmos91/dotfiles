{
  description = "Marmos91 Nix Configuration";

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
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      claude-code,
      home-manager,
      determinate,
      catppuccin,
      ...
    }:
    let
      # Configuration variables - change these for a different machine
      username = "marmos91";
      hostname = "amaterasu";

      # Helper to create pkgs for a system
      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ claude-code.overlays.default ];
      };
    in
    {
      nixpkgs.config.allowUnfree = true;

      # macOS configuration (nix-darwin + home-manager)
      darwinConfigurations = {
        ${hostname} = nix-darwin.lib.darwinSystem {
          pkgs = mkPkgs "aarch64-darwin";
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
                extraSpecialArgs = { inherit username hostname; homeDirectory = "/Users/${username}"; };
                users.${username} = {
                  imports = [
                    ./home
                    catppuccin.homeModules.catppuccin
                  ];
                };
              };
            }
          ];
        };
      };

      # Linux configuration (standalone home-manager)
      homeConfigurations = {
        ${username} = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = { inherit username hostname; homeDirectory = "/home/${username}"; };
          modules = [
            ./home
            catppuccin.homeModules.catppuccin
          ];
        };

        # ARM Linux variant (e.g., Raspberry Pi, ARM servers)
        "${username}-aarch64" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "aarch64-linux";
          extraSpecialArgs = { inherit username hostname; homeDirectory = "/home/${username}"; };
          modules = [
            ./home
            catppuccin.homeModules.catppuccin
          ];
        };
      };
    };
}
