{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # qBittorrent with web UI
    services.qbittorrent = {
      enable = true;
      port = 8080;
      openFirewall = true;
      user = "qbittorrent";
      group = "media";
      dataDir = "/space/config/qbittorrent";
    };

    # Create qbittorrent user
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
      extraGroups = [ "media" ];
    };

    # Ensure qBittorrent starts after /space is mounted
    systemd.services.qbittorrent.after = [ "space.mount" ];
    systemd.services.qbittorrent.requires = [ "space.mount" ];

    # Open qBittorrent web UI port
    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
