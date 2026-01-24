{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # Overseerr request management
    services.overseerr = {
      enable = true;
      port = 5055;
    };

    # Ensure Overseerr starts after /space is mounted
    systemd.services.overseerr.after = [ "space.mount" ];
    systemd.services.overseerr.requires = [ "space.mount" ];
  };
}
