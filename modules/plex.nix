{ config, pkgs, lib, ... }:

{
  imports = [
    ./plex/media-server.nix
    ./plex/downloads.nix
    ./plex/indexer.nix
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

    # Open Plex port in firewall
    networking.firewall.allowedTCPPorts = [ 32400 ];
  };
}
