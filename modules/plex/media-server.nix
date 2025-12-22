{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Plex Media Server
    services.plex = {
      enable = true;
      openFirewall = true;
      dataDir = "/space/config/plex";
      group = "media";
    };

    # Ensure Plex starts after /space is mounted
    systemd.services.plex.after = [ "space.mount" ];
    systemd.services.plex.requires = [ "space.mount" ];

    # Add plex user to media group
    users.users.plex.extraGroups = [ "media" ];
  };
}
