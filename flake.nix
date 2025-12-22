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
      system = "x86_64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations."aostow@laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./modules/terminal.nix
          ./modules/dev.nix
          ./modules/neovim.nix
          {
            home.username = "aostow";
            home.homeDirectory = "/Users/aostow";
            home.stateVersion = "23.11";

            programs.home-manager.enable = true;

            nixpkgs.config.allowUnfree = true;

            nix = {
              package = pkgs.nix;
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
            };

            # Laptop-specific packages (GUI apps, macOS-specific, personal tools)
            home.packages = with pkgs; [
              audacity
              darwin.libiconv
              ffmpeg
              imagemagick
              yt-dlp-light
            ];

            # Laptop-specific zsh configuration
            programs.zsh = {
              initExtra = ''
                export AWS_PROFILE=admin
              '';
            };
          }
        ];
      };
    };
}
