{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Radarr movie automation
    services.radarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/space/config/radarr";
      group = "media";
    };

    # Ensure Radarr starts after /space is mounted
    systemd.services.radarr.after = [ "space.mount" ];
    systemd.services.radarr.requires = [ "space.mount" ];

    # Radarr runs as its own user, add to media group
    users.users.radarr.extraGroups = [ "media" ];
  };
}
