{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
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
      agenix,
      home-manager,
      pre-commit-hooks,
      flake-utils,
      self,
      ...
    }:
    let
      darwinPkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      linuxPkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [
          (self: super: {
            decluttarr = self.python3Packages.callPackage ./pkgs/decluttarr { };
          })
        ];
      };
      lookupPkgs = {
        "aarch64-darwin" = darwinPkgs;
        "x86_64-linux" = linuxPkgs;
      };
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
              pkgs = lookupPkgs.${system};
              preCommitCheck = pre-commit-hooks.lib.${system}.run {
                src = ./.;
                hooks = {
                  nixfmt-rfc-style.enable = true;
                  flake-check = {
                    enable = true;
                    name = "flake-check";
                    entry = "${pkgs.nixVersions.latest}/bin/nix flake check";
                    files = "\\.(nix)$";
                    pass_filenames = false;
                  };
                };
              };
            in
            {
              apps.install-hooks = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "install-hooks" ''
                    ${preCommitCheck.shellHook}
                  ''
                );
              };
            }
          );
    in
    perSystemOutputs
    // {
      # macOS laptop (standalone home-manager)
      homeConfigurations."aostow@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = darwinPkgs;

        extraSpecialArgs = {
          inherit self;
          system = "aarch64-darwin";
        };

        modules = [
          ./home/profiles/laptop.nix
          ./home/modules/terminal.nix
          ./home/modules/dev.nix
          ./home/modules/neovim.nix
        ];
      };

      # NixOS server ultan (complete system + home-manager)
      nixosConfigurations.ultan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        pkgs = linuxPkgs;

        # allows you to pass outputs from this flake into packages that use .callPackage (I think?)
        specialArgs = {
          inherit self;
          system = "x86_64-linux";
        };

        modules = [
          agenix.nixosModules.default
          # Hardware configuration
          ./nixos/hosts/ultan-hardware.nix
          # System configuration
          ./nixos/hosts/ultan.nix
          # Media stack
          ./nixos/modules/plex.nix
          # Reverse proxy
          ./nixos/modules/caddy.nix
          # DDNS
          ./nixos/modules/ddns.nix
          # WireGuard VPN
          ./nixos/modules/wireguard.nix
          ./nixos/modules/wireguard-tools.nix
          # Pi-hole DNS with ad-blocking
          ./nixos/modules/pihole.nix
          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit self;
                system = "x86_64-linux";
              };
              users.aostow = {
                imports = [
                  ./home/profiles/ultan.nix
                  ./home/modules/terminal.nix
                  ./home/modules/neovim.nix
                  # Add ./home/modules/dev.nix if you want dev tools on server
                ];
              };
            };
          }
        ];
      };
    };
}
