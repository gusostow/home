{ config, pkgs, ... }:

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

  # Laptop-specific packages (GUI apps, macOS-specific, personal tools)
  home.packages = with pkgs; [
    audacity
    darwin.libiconv
    ffmpeg
    imagemagick
    yt-dlp-light
  ];

  # Laptop-specific zsh configuration
  programs.zsh = {
    initExtra = ''
      export AWS_PROFILE=admin
    '';
  };
}
