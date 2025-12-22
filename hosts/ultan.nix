{ config, pkgs, ... }:

{
  home.username = "aostow";
  home.homeDirectory = "/home/aostow";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # Server-specific packages (if any)
  home.packages = with pkgs; [
    dig
    unixtools.ifconfig
  ];
}
