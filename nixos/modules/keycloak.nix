{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.keycloak-db-password = {
    file = ../../secrets/keycloak-db-password.age;
    mode = "0400";
  };

  # keycloak identity provider
  services.keycloak = {
    enable = true;

    database = {
      type = "postgresql";
      createLocally = true; # NixOS manages PostgreSQL database and authentication
      passwordFile = config.age.secrets.keycloak-db-password.path;
    };

    settings = {
      # bind to localhost only - Caddy handles external access
      http-host = "127.0.0.1";
      http-port = 8180;

      # proxy settings for Caddy
      proxy-headers = "xforwarded";
      http-enabled = true;

      # hostname configuration
      hostname = "idp.home";
      hostname-strict = false;
    };
  };

  # ensure Keycloak starts after PostgreSQL is ready
  systemd.services.keycloak = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
}
