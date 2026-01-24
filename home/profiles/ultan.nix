{ config, pkgs, ... }:

{
  home.username = "aostow";
  home.homeDirectory = "/home/aostow";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    dig
    ethtool
    unixtools.ifconfig
    unixtools.netstat
  ];

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
