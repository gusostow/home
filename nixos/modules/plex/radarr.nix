{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Radarr movie automation
    services.radarr = {
      enable = true;
      openFirewall = false;
      dataDir = "/space/config/radarr";
      group = "media";
    };

    # Ensure Radarr starts after /space is mounted
    systemd.services.radarr.after = [ "space.mount" ];
    systemd.services.radarr.requires = [ "space.mount" ];

    # Set umask so new files/dirs are group-writeable (775 for dirs, 664 for files)
    systemd.services.radarr.serviceConfig.UMask = "0002";

    # Radarr runs as its own user, add to media group
    users.users.radarr.extraGroups = [ "media" ];
  };
}
