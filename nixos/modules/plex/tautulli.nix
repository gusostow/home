{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Tautulli - Plex monitoring and statistics
    services.tautulli = {
      enable = true;
      port = 8181;
      dataDir = "/space/config/tautulli";
      group = "media";
    };

    # Ensure Tautulli starts after /space is mounted
    systemd.services.tautulli.after = [ "space.mount" ];
    systemd.services.tautulli.requires = [ "space.mount" ];

    # Set umask so new files/dirs are group-writeable
    systemd.services.tautulli.serviceConfig.UMask = "0002";

    # Add tautulli user to media group
    users.groups.tautulli = { };
    users.users.tautulli = {
      group = "tautulli";
      extraGroups = [ "media" ];
      isSystemUser = true;
    };
  };
}
