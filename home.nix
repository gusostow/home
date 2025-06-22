# TODO: flake
# TODO: nix linting
# TODO: vim comment hotkey
# TODO: try out spacebar leader
# TODO: harpoon
# TODO: break lua init into separate files
# TODO: pin nixpkgs in this config file?
# TODO: global gitignore

{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "aostow";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    autojump
    awscli2
    bat
    cargo
    coreutils
    curl
    code-cursor
    darwin.libiconv
    direnv
    docker
    du-dust
    flyctl
    fzf
    gcc
    git
    go
    gopls
    helix
    htop
    hyperfine
    nixfmt-rfc-style
    pandoc
    postgresql
    protobuf
    pstree
    ripgrep
    rust-analyzer
    rustc
    rustfmt
    rustlings
    sqlite
    s5cmd
    tldr
    tmux
    tree
    uv
    wget
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
    initContent = pkgs.lib.mkBefore (
      ''
        set -o vi

        bindkey '^E' autosuggest-accept
        bindkey '^P' up-line-or-history
        bindkey '^N' down-line-or-history

        # unbind fzf-cd-widget, set by fzf/shell/key-bindings.sh
        bindkey -r '\ec'

        if [[ -f $HOME/.config/secrets ]]; then
            source $HOME/.config/secrets
        fi
      '' + builtins.readFile sh/utils.sh + ''
        # Prepend a magenta "nix-shell" tag to the left prompt when inside a nix shell.
        function _nix_shell_prompt() {
          # Save original prompt once
          if [[ -z "$__ORIG_PROMPT_SAVED" ]]; then
            __ORIG_PROMPT="$PROMPT"
            __ORIG_PROMPT_SAVED=1
          fi
          if [[ -n "$IN_NIX_SHELL" ]]; then
            PROMPT="%F{magenta}nix-shell%f $__ORIG_PROMPT"
          else
            PROMPT="$__ORIG_PROMPT"
          fi
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _nix_shell_prompt
      ''
    );
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      c = "clear";
      cat = "bat";
      g = "git";
      gs = "git status";
      gco = "git checkout";
    };

    sessionVariables = {
      EDITOR = "nvim";
      PYTHONBREAKPOINT = "ipdb.set_trace";
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
    extraConfig = builtins.readFile tmux/.tmux.conf;
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
      coc-go # required me to manually install xcode
      coc-lua
      coc-pairs
      coc-pyright
      coc-rust-analyzer
      coc-sh
      coc-yaml
      fzf-vim
      harpoon
      oceanic-next
      vim-fugitive
      vim-nix
    ];
    extraPackages = with pkgs; [
      gopls # coc doesn't seem to register this
    ];
    extraPython3Packages = (
      ps: with ps; [
        isort
        black
      ]
    );
    coc = {
      enable = true;
      settings = {
        "python.formatting.provider" = "black";
        "python.pythonPath" = "nvim-python3";
        "inlayHint.enable" = false;
      };

    };
    extraLuaConfig = builtins.readFile nvim/coc.lua + builtins.readFile nvim/init.lua;
  };
}
