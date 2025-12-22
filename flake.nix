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
              arduino-cli
              audacity
              darwin.libiconv
              dust
              ffmpeg
              helix
              hyperfine
              imagemagick
              yt-dlp-light
            ];

            # Laptop-specific zsh configuration
            programs.zsh = {
              initExtra = ''
                export AWS_PROFILE=admin
                export PATH=$PATH:~/.npm-global/bin
              '';
              sessionVariables = {
                PYTHONBREAKPOINT = "ipdb.set_trace";
                RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
              };
            };

            programs.neovim = {
              enable = true;
              withPython3 = true;
              plugins = with pkgs.vimPlugins; [
                coc-clangd
                coc-fzf
                coc-json
                coc-go
                coc-lua
                coc-pairs
                coc-pyright
                coc-rust-analyzer
                coc-sh
                coc-tsserver
                coc-yaml
                fzf-vim
                harpoon
                oceanic-next
                vim-fugitive
                vim-nix
              ];
              extraPackages = with pkgs; [
                gopls
                ruff
                terraform-ls
              ];
              extraPython3Packages = (
                ps: with ps; [
                  isort
                ]
              );
              coc = {
                enable = true;
                settings = {
                  "python.formatting.provider" = "ruff";
                  "python.pythonPath" = "nvim-python3";
                  "inlayHint.enable" = false;
                  "terraform.languageServer.path" = "terraform-ls";
                  "terraform.languageServer.args" = "serve";
                  "terraform.formatOnSave" = true;
                };
              };
              extraLuaConfig = builtins.readFile ./nvim/coc.lua + builtins.readFile ./nvim/init.lua;
            };
          }
        ];
      };
    };
}
