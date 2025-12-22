{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # qBittorrent with web UI
    services.qbittorrent = {
      enable = true;
      port = 8080;
      openFirewall = true;
      group = "media";
    };

    # Ensure qBittorrent starts after /space is mounted
    systemd.services.qbittorrent.after = [ "space.mount" ];
    systemd.services.qbittorrent.requires = [ "space.mount" ];

    # Configure qBittorrent state directory to be on /space
    systemd.services.qbittorrent.serviceConfig = {
      StateDirectory = lib.mkForce "qbittorrent";
      StateDirectoryMode = "0750";
    };

    # Create symlink from default location to /space
    systemd.tmpfiles.rules = [
      "L+ /var/lib/qbittorrent - - - - /space/config/qbittorrent"
    ];
  };
}
