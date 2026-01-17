{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      darwinSystem = "x86_64-darwin";
      darwinPkgs = import nixpkgs {
        system = darwinSystem;
        config.allowUnfree = true;
      };
    in
    {
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

      # NixOS server ultan (complete system + home-manager)
      nixosConfigurations.ultan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware configuration
          ./hosts/ultan-hardware.nix

          # System configuration
          ./hosts/ultan-system.nix

          # Media stack
          ./modules/plex.nix

          # Reverse proxy
          ./modules/caddy.nix

          # DDNS
          ./modules/ddns.nix

          # WireGuard VPN
          ./modules/wireguard.nix
          ./modules/wireguard-tools.nix

          # Pi-hole DNS with ad-blocking
          ./modules/pihole.nix

          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.aostow = {
                imports = [
                  ./hosts/ultan.nix
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
