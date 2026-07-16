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
    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      determinate,
      catppuccin,
      sops-nix,
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
        overlays = [
          # nushell 0.112.1 has two SHLVL tests that fail in the Nix sandbox
          (final: prev: {
            nushell = prev.nushell.overrideAttrs (_: { doCheck = false; });
          })
        ];
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
                extraSpecialArgs = { inherit username hostname; homeDirectory = "/Users/${username}"; isWSL = false; };
                users.${username} = {
                  imports = [
                    ./home
                    catppuccin.homeModules.catppuccin
                    sops-nix.homeManagerModules.sops
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
          extraSpecialArgs = { inherit username hostname; homeDirectory = "/home/${username}"; isWSL = false; };
          modules = [
            ./home
            catppuccin.homeModules.catppuccin
            sops-nix.homeManagerModules.sops
          ];
        };

        # ARM Linux variant (e.g., Raspberry Pi, ARM servers)
        "${username}-aarch64" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "aarch64-linux";
          extraSpecialArgs = { inherit username hostname; homeDirectory = "/home/${username}"; isWSL = false; };
          modules = [
            ./home
            catppuccin.homeModules.catppuccin
            sops-nix.homeManagerModules.sops
          ];
        };

        # Windows via WSL2 (Ubuntu) — same Linux home-manager config, minus
        # GUI-only pieces (GNOME desktop, GUI terminal emulators) that have
        # nowhere to run inside WSL2. The GUI terminal (WezTerm) is installed
        # natively on the Windows side instead (see windows/bootstrap.ps1).
        "${username}-wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          extraSpecialArgs = { inherit username hostname; homeDirectory = "/home/${username}"; isWSL = true; };
          modules = [
            ./home
            catppuccin.homeModules.catppuccin
            sops-nix.homeManagerModules.sops
          ];
        };
      };
    };
}
