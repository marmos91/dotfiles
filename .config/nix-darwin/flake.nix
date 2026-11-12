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
    # Skill pack for AI coding agents (poteto-mode, tdd, blast-radius, ...).
    # Plain source tree — linked into ~/.agents/skills by home/pstack.nix.
    # `nix flake update` bumps it; `rebuild` applies the new revision.
    pstack = {
      url = "github:backnotprop/pstack";
      flake = false;
    };
    # My own agent skills (repo-audit, repo-audit-fix, refute-root-cause),
    # pinned and linked the same way as pstack.
    mySkills = {
      url = "github:marmos91/skills";
      flake = false;
    };
    # Davide's Claude Code <-> Mimir gateway (it-router). Built from source
    # by home/programs/utilities/claude-mimir.nix. Our fork keeps Mimir's
    # reasoning across turns (didimelli/claude-mimir#10); switch back to
    # github:didimelli/claude-mimir once that merges.
    claude-mimir = {
      url = "github:marmos91/claude-mimir/fix/replay-reasoning";
      flake = false;
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
      pstack,
      mySkills,
      ...
    }:
    let
      # Configuration variables - change these for a different machine
      username = "marmos91";
      hostname = "amaterasu";

      # Helper to create pkgs for a system
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Shared specialArgs for every home-manager configuration below.
      # `inputs` lets home modules reach any flake input by name — adding
      # one never touches this block again.
      hmArgs = {
        inherit username hostname inputs;
        homeDirectory = "/Users/${username}";
      };
      # The home-manager module list, shared by the darwin and Linux outputs.
      homeModules = [
        ./home
        catppuccin.homeModules.catppuccin
        sops-nix.homeManagerModules.sops
      ];
      makeHomeConfig =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = hmArgs // {
            homeDirectory = "/home/${username}";
          };
          modules = homeModules;
        };
    in
    {
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
                extraSpecialArgs = hmArgs;
                users.${username}.imports = homeModules;
              };
            }
          ];
        };
      };

      # Linux configuration (standalone home-manager)
      homeConfigurations = {
        ${username} = makeHomeConfig "x86_64-linux";

        # ARM Linux variant (e.g., Raspberry Pi, ARM servers)
        "${username}-aarch64" = makeHomeConfig "aarch64-linux";
      };
    };
}
