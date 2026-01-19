{ config, pkgs, ... }:

{
  home.username = "aostow";
  home.homeDirectory = "/Users/aostow";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = "auto";
    };
    registry.home = {
      from = {
        id = "home";
        type = "indirect";
      };
      to = {
        path = "/Users/aostow/dev/home";
        type = "path";
      };
    };
  };

  # Laptop-specific packages (GUI apps, macOS-specific, personal tools)
  home.packages = with pkgs; [
    audacity
    darwin.libiconv
    ffmpeg
    imagemagick
    wireguard-tools
    yt-dlp-light
  ];

  # Laptop-specific zsh configuration
  programs.zsh = {
    initContent = ''
      export AWS_PROFILE=admin
    '';
  };
}
