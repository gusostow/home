{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./plex/media-server.nix
    ./plex/downloads.nix
    ./plex/indexer.nix
    ./plex/radarr.nix
    ./plex/sonarr.nix
    ./plex/overseerr.nix
    ./plex/unpackerr.nix
    ./plex/decluttarr.nix
  ];

  # Shared configuration for media stack
  options.services.mediaStack = {
    enable = lib.mkEnableOption "media stack";
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/space";
      description = "Base directory for all media stack data";
    };
  };

  config = lib.mkIf config.services.mediaStack.enable {
    # Create shared media group
    users.groups.media = {
      gid = 1500;
    };

    # Create directory structure with correct permissions
    systemd.tmpfiles.rules = [
      "d /space/media 0775 root media -"
      "d /space/media/movies 0775 root media -"
      "d /space/media/tv 0775 root media -"
      "d /space/media/music 0775 root media -"
      "d /space/downloads 0775 root media -"
      "d /space/downloads/complete 0775 root media -"
      "d /space/downloads/incomplete 0775 root media -"
      "d /space/config 0775 root media -"
    ];

    services.decluttarr = {
      settings = ''
        general:
          log_level: VERBOSE
          timer: 1  # min
        jobs:
          remove_failed_downloads:
          remove_failed_imports:
          remove_stalled:
        instances:
          sonarr:
            - base_url: "http://localhost:8989"
              api_key: !ENV SONARR_API_KEY
          radarr:
            - base_url: "http://localhost:7878"
              api_key: !ENV RADARR_API_KEY
        download_clients:
          qbittorrent:
            - base_url: "http://localhost:8080"
              username: admin
              password: !ENV QBITTORRENT_PASSWORD
      '';
    };
  };
}
