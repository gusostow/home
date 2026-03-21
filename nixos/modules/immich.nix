{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.immich-oidc-secret = {
    file = ../../secrets/immich-oidc-secret.age;
    mode = "0400";
    owner = "immich";
  };

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

      # OAuth/OIDC configuration with Keycloak
      oauth = {
        enabled = true;
        issuerUrl = "https://idp.home/realms/home";
        clientId = "immich";
        clientSecret._secret = config.age.secrets.immich-oidc-secret.path;
        scope = "openid email profile";
        buttonText = "Login with Keycloak";
        autoRegister = true;
        autoLaunch = false;
      };
    };
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
