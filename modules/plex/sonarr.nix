{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Sonarr TV show automation
    services.sonarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/space/config/sonarr";
      group = "media";
    };

    # Ensure Sonarr starts after /space is mounted
    systemd.services.sonarr.after = [ "space.mount" ];
    systemd.services.sonarr.requires = [ "space.mount" ];

    # Sonarr runs as its own user, add to media group
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
