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

    # wait for HTTP endpoint to be ready before marking service as started
    # this prevents oauth2-proxy from starting before keycloak is ready
    serviceConfig = {
      ExecStartPost = "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do ${pkgs.curl}/bin/curl -sf http://127.0.0.1:8180 >/dev/null && exit 0; sleep 1; done; exit 1'";
    };
  };
}
