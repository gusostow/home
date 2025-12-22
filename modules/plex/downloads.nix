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
    };

    # Create qbittorrent user
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
    };

    # Ensure qBittorrent starts after /space is mounted
    systemd.services.qbittorrent.after = [ "space.mount" ];
    systemd.services.qbittorrent.requires = [ "space.mount" ];
  };
}
