# TODO: ipython custom module

{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "aostow";
  home.homeDirectory = "/Users/aostow";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    autojump
    awscli2
    bat
    coreutils
    curl
    docker
    du-dust
    fzf
    git
    hyperfine
    nixfmt
    poetry
    postgresql
    ripgrep
    sqlite
    tldr
    tmux
    tree
    wget
    (python3.withPackages
      (p: with p; [ boto3 ipython jupyter numpy pandas requests ]))
  ];

  programs.zsh = {
    enable = true;
    initExtraFirst = ''
      set -o vi
      bindkey '^E' autosuggest-accept
      bindkey '^P' up-line-or-history
      bindkey '^N' down-line-or-history

      if [[ -f $HOME/.config/secrets ]]; then
          source $HOME/.config/secrets
      fi
    '' + builtins.readFile sh/utils.sh;
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ...";
      c = "clear";
      cat = "bat";
      g = "git";
      gs = "git status";
      gco = "git checkout";
    };

    sessionVariables = { EDITOR = "nvim"; };

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
      oceanic-next
      fzf-vim
      vim-fugitive
      vim-nix # syntax highlighting
      coc-fzf
      coc-json
      coc-pairs
      coc-pyright
      coc-sh
      coc-yaml
    ];
    extraPython3Packages = (ps: with ps; [ isort black ]);
    coc = {
      enable = true;
      settings = {
        "python.formatting.provider" = "black";
        "python.pythonPath" = "nvim-python3";
      };

    };
    extraConfig = ''
      set ignorecase
      set smartcase
      set autoindent 
      set smartindent
      set shiftwidth=4
      set softtabstop=4
      set tabstop=4
      set expandtab
      filetype indent plugin on 
      let g:pyindent_open_paren = 'shiftwidth()'
      set confirm
      set number

      colorscheme OceanicNext
      set colorcolumn=88
      set statusline+=%F

      nmap Y "+y
      vmap Y "+y

      nnoremap <C-h> :tabprevious<CR>
      nnoremap <C-l> :tabnext<CR>

      set hlsearch
      nnoremap <C-[> :nohl<CR><C-[>

      nmap <Leader>h  :e $HOME/dev/home/home.nix<CR>
      nmap <Leader>sv :source $MYVIMRC<CR>
      nmap <Leader>cp :let @+ = expand("%:p")<CR>

      map <leader>ew :e     <C-R>=expand("%:p:h") . "/" <CR>
      map <leader>ev :sp    <C-R>=expand("%:p:h") . "/" <CR>
      map <leader>et :tabe  <C-R>=expand("%:p:h") . "/" <CR>

      nmap <leader>F  :Format<CR>
    '' + builtins.readFile nvim/coc.vim;
  };
}

