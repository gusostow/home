{ config, pkgs, ... }:

{
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
      vim-gitgutter
      vim-nix
    ];

    extraPackages = with pkgs; [
      gopls
      nixd
      nixfmt-rfc-style
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
        "languageserver" = {
          "nix" = {
            "command" = "nixd";
            "filetypes" = [ "nix" ];
          };
        };
        "nixd" = {
          "nixpkgs" = {
            "expr" = "(builtins.getFlake \"${toString ../.}\").inputs.nixpkgs { }";
          };
          "formatting" = {
            "command" = [ "nixfmt" ];
          };
        };
      };
    };

    extraLuaConfig = builtins.readFile ../nvim/coc.lua + builtins.readFile ../nvim/init.lua;
  };
}
