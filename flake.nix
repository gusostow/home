{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      darwinSystem = "x86_64-darwin";
      darwinPkgs = import nixpkgs {
        system = darwinSystem;
        config.allowUnfree = true;
      };
    in {
      # macOS laptop (standalone home-manager)
      homeConfigurations."aostow@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = darwinPkgs;

        modules = [
          ./hosts/laptop.nix
          ./modules/terminal.nix
          ./modules/dev.nix
          ./modules/neovim.nix
        ];
      };

      # NixOS server (complete system + home-manager)
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware configuration
          ./hosts/server-hardware.nix

          # System configuration
          ./hosts/server-system.nix

          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.aostow = {
                imports = [
                  ./hosts/server.nix
                  ./modules/terminal.nix
                  ./modules/neovim.nix
                  # Add ./modules/dev.nix if you want dev tools on server
                ];
              };
            };
          }
        ];
      };
    };
}
