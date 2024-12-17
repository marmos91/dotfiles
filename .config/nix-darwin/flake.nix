{
  description = "Marmos91 Darwin Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # _1password-shell-plugins = {
    #   url = "github:1Password/shell-plugins";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }: 
  {
    nixpkgs.config.allowUnfree = true;

    darwinConfigurations = {
      amaterasu = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [ 
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # home-manager.sharedModules = [
            #   (inputs._1password-shell-plugins.hmModules.default)
            # ];

            home-manager.users.marmos91 = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
    };
  };
}
