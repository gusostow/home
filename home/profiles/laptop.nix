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

  # laptop-specific packages (GUI apps, macOS-specific, personal tools)
  home.packages = with pkgs; [
    audacity
    awscli2
    darwin.libiconv
    ffmpeg
    imagemagick
    wireguard-tools
    xquartz
    yt-dlp-light
  ];

  home.sessionVariables = {
    AWS_PROFILE = "management";
  };

  # AWS CLI configuration with SSO profiles for multi-account setup
  home.file.".aws/config".text = ''
    [profile management]
    sso_start_url = https://d-90663f6afd.awsapps.com/start
    sso_region = us-east-1
    sso_account_id = 343364315281
    sso_role_name = AdministratorAccess
    region = us-east-1
    output = json

    [profile app-dev]
    sso_start_url = https://d-90663f6afd.awsapps.com/start
    sso_region = us-east-1
    sso_account_id = 253685958455
    sso_role_name = AdministratorAccess
    region = us-east-1
    output = json

    [profile app-prod]
    sso_start_url = https://d-90663f6afd.awsapps.com/start
    sso_region = us-east-1
    sso_account_id = 268769775110
    sso_role_name = AdministratorAccess
    region = us-east-1
    output = json

    [profile home]
    sso_start_url = https://d-90663f6afd.awsapps.com/start
    sso_region = us-east-1
    sso_account_id = 907689526840
    sso_role_name = AdministratorAccess
    region = us-east-1
    output = json
  '';

  # Laptop-specific zsh configuration
  programs.zsh = {
    initContent = ''
      function po {
        ps -o user,state,pid,pgid,ppid,%cpu,%mem,rss,start,command "$@"
      }
    '';
    shellAliases = {
      # "home" alias is defined in Nix flake registry
      "nix-switch" = "home-manager switch --flake home#aostow@laptop";
    };
  };
}
