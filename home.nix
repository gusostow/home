# TODO: flake
# TODO: vim comment hotkey
# TODO: try out spacebar leader
# TODO: harpoon
# TODO: break lua init into separate files
# TODO: fix golang lsp
# TODO: nix linting
# TODO: separate zshrc

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

  home.packages = with pkgs; [
    autojump
    awscli2
    bat
    coreutils
    curl
    docker
    du-dust
    flyctl
    fzf
    gcc
    git
    go
    htop
    hyperfine
    nixfmt
    pandoc
    poetry
    postgresql
    ripgrep
    sqlite
    s5cmd
    tldr
    tmux
    tree
    wget
    (python3.withPackages
      (p: with p; [ boto3 ipdb ipython jupyter numpy pandas pip requests rich sphinx ]))
  ];

  programs.zsh = {
    enable = true;
    initExtraFirst = ''
      set -o vi

      bindkey '^E' autosuggest-accept
      bindkey '^P' up-line-or-history
      bindkey '^N' down-line-or-history

      # unbind fzf-cd-widget, set by fzf/shell/key-bindings.sh
      bindkey -r '\ec'

      if [[ -f $HOME/.config/secrets ]]; then
          source $HOME/.config/secrets
      fi
    '' + builtins.readFile sh/utils.sh;
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

    enableAutosuggestions = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" ];
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
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.autojump.enable = true;

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
      coc-sh
      coc-yaml
      fzf-vim
      harpoon
      oceanic-next
      vim-fugitive
      vim-nix
    ];
    extraPython3Packages = (ps: with ps; [ isort black ]);
    coc = {
      enable = true;
      settings = {
        "python.formatting.provider" = "black";
        "python.pythonPath" = "nvim-python3";
      };

    };
    extraLuaConfig = builtins.readFile nvim/init.lua + builtins.readFile nvim/coc.lua;
  };
}

