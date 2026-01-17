{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      darwinPkgs = import nixpkgs {
        system = darwinSystem;
        config.allowUnfree = true;
      };

      linuxPkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfree = true;
      };

      # Pre-commit hooks configuration for each system
      mkPreCommitCheck =
        system:
        pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
          };
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

      # Apps for installing pre-commit hooks
      apps.${darwinSystem}.install-hooks = {
        type = "app";
        program = toString (
          darwinPkgs.writeShellScript "install-hooks" ''
            ${(mkPreCommitCheck darwinSystem).shellHook}
          ''
        );
      };

      apps.${linuxSystem}.install-hooks = {
        type = "app";
        program = toString (
          linuxPkgs.writeShellScript "install-hooks" ''
            ${(mkPreCommitCheck linuxSystem).shellHook}
          ''
        );
      };

      # Development shells
      devShells.${darwinSystem}.default = darwinPkgs.mkShell {
        buildInputs = [ darwinPkgs.nixfmt-rfc-style ];
      };

      devShells.${linuxSystem}.default = linuxPkgs.mkShell {
        buildInputs = [ linuxPkgs.nixfmt-rfc-style ];
      };
    };
}
