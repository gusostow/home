{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Lidarr music automation
    services.lidarr = {
      enable = true;
      openFirewall = false;
      dataDir = "/space/config/lidarr";
      group = "media";
    };

    # Ensure Lidarr starts after /space is mounted
    systemd.services.lidarr.after = [ "space.mount" ];
    systemd.services.lidarr.requires = [ "space.mount" ];

    # Set umask so new files/dirs are group-writeable (775 for dirs, 664 for files)
    systemd.services.lidarr.serviceConfig.UMask = "0002";

    # Lidarr runs as its own user, add to media group
    users.users.lidarr.extraGroups = [ "media" ];
  };
}
