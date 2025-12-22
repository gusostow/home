{ config, pkgs, ... }:

{
  home.username = "aostow";
  home.homeDirectory = "/home/aostow";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  # Server-specific packages (if any)
  home.packages = with pkgs; [
    # Add server-specific tools here if needed
    # Most tools come from terminal.nix, dev.nix, neovim.nix
  ];
}
