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

    # Configure download paths via preStart script
    systemd.services.qbittorrent = {
      after = [ "space.mount" ];
      requires = [ "space.mount" ];

      preStart = ''
        mkdir -p /space/config/qbittorrent/qBittorrent/config

        # Set download directories if config doesn't exist or needs updating
        CONFIG_FILE="/space/config/qbittorrent/qBittorrent/config/qBittorrent.conf"

        if [ ! -f "$CONFIG_FILE" ]; then
          cat > "$CONFIG_FILE" <<EOF
[Preferences]
Downloads\\SavePath=/space/downloads/complete
Downloads\\TempPath=/space/downloads/incomplete
Downloads\\TempPathEnabled=true
EOF
          chown qbittorrent:media "$CONFIG_FILE"
        fi
      '';
    };
  };
}
