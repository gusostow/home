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
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      flake-utils,
      self,
      ...
    }:
    let
      # Per-system outputs (packages, apps, devShells)
      perSystemOutputs =
        flake-utils.lib.eachSystem
          [
            "aarch64-darwin"
            "x86_64-linux"
          ]
          (
            system:
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };

              preCommitCheck = pre-commit-hooks.lib.${system}.run {
                src = ./.;
                hooks = {
                  nixfmt-rfc-style.enable = true;
                };
              };
            in
            {
              packages.decluttarr = pkgs.python3Packages.callPackage ./pkgs/decluttarr { };

              apps.install-hooks = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "install-hooks" ''
                    ${preCommitCheck.shellHook}
                  ''
                );
              };

              devShells.default = pkgs.mkShell { buildInputs = [ pkgs.nixfmt-rfc-style ]; };
            }
          );

      # System-specific configurations
      darwinPkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
    in
    perSystemOutputs
    // {
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

        # allows you to pass outputs from this flake into packages that use .callPackage (I think?)
        specialArgs = {
          inherit self;
          system = "x86_64-linux";
        };

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
