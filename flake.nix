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

            home.packages = with pkgs; [
              arduino-cli
              audacity
              awscli2
              nodePackages.aws-cdk
              bat
              cargo-lambda
              cmake
              coreutils
              curl
              darwin.libiconv
              docker
              dust
              ffmpeg
              flyctl
              # fx  # Temporarily disabled due to flaky tests
              gcc
              go
              gopls
              helix
              htop
              hyperfine
              imagemagick
              jq
              libllvm
              nixfmt-rfc-style
              nodejs
              pandoc
              platformio
              postgresql
              protobuf
              pstree
              ripgrep
              rustup
              sqlite
              s5cmd
              terraform
              tldr
              tree
              uv
              wget
              yt-dlp-light
              zig
              (python3.withPackages (
                p: with p; [
                  boto3
                  cookiecutter
                  grpcio-tools
                  ipdb
                  ipython
                  jupyter
                  numpy
                  pandas
                  pillow
                  pip
                  pipx
                  python-lsp-server
                  requests
                  rich
                  sphinx
                ]
              ))
            ];

            programs.zsh = {
              enable = true;
              history.save = 1000000;
              plugins = [
                {
                  name = "zsh-nix-shell";
                  file = "nix-shell.plugin.zsh";
                  src = pkgs.fetchFromGitHub {
                    owner = "chisui";
                    repo = "zsh-nix-shell";
                    rev = "v0.8.0";
                    sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
                  };
                }
              ];
              initExtra = pkgs.lib.mkBefore (
                ''
                  set -o vi

                  bindkey '^E' autosuggest-accept
                  bindkey '^P' up-line-or-history
                  bindkey '^N' down-line-or-history

                  # unbind fzf-cd-widget, set by fzf/shell/key-bindings.sh
                  bindkey -r '\ec'

                  export AWS_PROFILE=admin

                  export PATH=$PATH:~/.npm-global/bin

                  export LIBRARY_PATH=~/.nix-profile/lib

                  if [[ -f $HOME/.config/secrets ]]; then
                      source $HOME/.config/secrets
                  fi
                ''
                + builtins.readFile ./sh/utils.sh
              );
              shellAliases = {
                ".." = "cd ..";
                "..." = "cd ../..";
                c = "clear";
                cat = "bat";
                g = "git";
                gs = "git status";
                gco = "git checkout";
                push = "git push origin HEAD";
              };

              sessionVariables = {
                EDITOR = "nvim";
                PYTHONBREAKPOINT = "ipdb.set_trace";
                RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
              };

              autosuggestion = {
                enable = true;
              };

              oh-my-zsh = {
                enable = true;
                plugins = [
                  "git"
                  "docker"
                ];
                theme = "robbyrussell";
              };
            };

            programs.tmux = {
              enable = true;
              prefix = "C-a";
              keyMode = "vi";
              escapeTime = 10;
              historyLimit = 5000;
              terminal = "xterm-256color";
              extraConfig = builtins.readFile ./tmux/.tmux.conf;
            };

            programs.git = {
              enable = true;
              userName = "Augustus Ostow";
              userEmail = "ostowster@gmail.com";
              aliases = {
                co = "checkout";
                s = "status";
              };
              extraConfig = {
                init.defaultBranch = "main";
              };
            };

            programs.fzf = {
              enable = true;
              enableZshIntegration = true;
            };

            programs.autojump.enable = true;

            programs.zoxide = {
              enable = true;
              enableZshIntegration = true;
            };

            programs.direnv = {
              enable = true;
              enableZshIntegration = true;
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
