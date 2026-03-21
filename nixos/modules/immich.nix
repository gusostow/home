{
  config,
  pkgs,
  lib,
  ...
}:

{
  # immich photo management service
  services.immich = {
    enable = true;

    # bind to localhost only - Caddy handles external access
    host = "127.0.0.1";
    port = 2283;

    # media storage location
    mediaLocation = "/space/immich";

    settings = {
      server = {
        externalDomain = "https://photos.home";
      };
    };

    # OAuth/OIDC configuration with Keycloak
    # note: OAuth is configured through the web UI at https://photos.home/admin/system-settings
    # Required settings:
    # - Enable: true
    # - Issuer URL: https://idp.home/realms/home
    # - Client ID: immich
    # - Client Secret: (from Keycloak client credentials tab)
    # - Scope: openid profile email
    # - Button Text: Login with Keycloak (optional)
    # - Auto Register: true (to allow new Keycloak users to create accounts)
  };

  # ensure media directory exists and has correct permissions
  systemd.tmpfiles.rules = [
    "d /space/immich 0750 immich immich -"
  ];

  # ensure Immich starts after the merged filesystem is ready
  systemd.services.immich-server = {
    after = [ "space.mount" ];
    requires = [ "space.mount" ];
  };
}
