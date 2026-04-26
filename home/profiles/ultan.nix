{ config, pkgs, ... }:

{
  home.username = "aostow";
  home.homeDirectory = "/home/aostow";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # most server-specific packages are installed at host level in nixos/hosts/ultan.nix.
  home.packages = with pkgs; [ ];

  programs.zsh = {
    initContent = ''
      function po {
        ps -H -o user:10,state,pid,pgid,ppid,pcpu,pmem,rss,start,cmd --headers "$@"
      }
    '';
    shellAliases = {
      # "home" alias is defined in Nix flake registry
      "nix-switch" = "sudo nixos-rebuild switch --refresh --flake home#ultan";
    };
  };
}
