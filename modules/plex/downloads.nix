{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # qBittorrent with web UI
    services.qbittorrent = {
      enable = true;
      webuiPort = 8080;
      openFirewall = true;
      user = "qbittorrent";
      group = "media";
      profileDir = "/space/config/qbittorrent";

      # Configure download paths
      serverConfig = {
        Preferences = {
          Downloads = {
            SavePath = "/space/downloads/complete";
            TempPath = "/space/downloads/incomplete";
            TempPathEnabled = true;
          };
        };
      };
    };

    # Create qbittorrent user
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
    };

    # Ensure qBittorrent starts after /space is mounted
    systemd.services.qbittorrent = {
      after = [ "space.mount" ];
      requires = [ "space.mount" ];

      # Set umask so created files/dirs are group-writable
      serviceConfig.UMask = "0002";
    };
  };
}
