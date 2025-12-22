{ config, pkgs, ... }:

{
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

        export LIBRARY_PATH=~/.nix-profile/lib

        if [[ -f $HOME/.config/secrets ]]; then
            source $HOME/.config/secrets
        fi
      ''
      + builtins.readFile ../sh/utils.sh
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
    extraConfig = builtins.readFile ../tmux/.tmux.conf;
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

  # Core CLI tools for terminal work
  home.packages = with pkgs; [
    bat
    coreutils
    curl
    dust
    fx
    helix
    htop
    jq
    ripgrep
    tree
    wget
  ];
}
