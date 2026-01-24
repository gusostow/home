{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Prowlarr indexer manager
    services.prowlarr = {
      enable = true;
      openFirewall = false;
    };

    # Ensure Prowlarr starts after /space is mounted
    systemd.services.prowlarr.after = [ "space.mount" ];
    systemd.services.prowlarr.requires = [ "space.mount" ];

    # Create prowlarr user
    users.users.prowlarr = {
      isSystemUser = true;
      group = "media";
    };
  };
}
