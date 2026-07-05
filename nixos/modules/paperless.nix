{
  config,
  pkgs,
  lib,
  ...
}:

{
  age.secrets.paperless-env = {
    file = ../../secrets/paperless-env.age;
    mode = "0400";
    owner = "paperless";
  };

  services.paperless = {
    enable = true;

    # bind to localhost only - Caddy handles external access
    address = "127.0.0.1";

    # storage locations on merged filesystem
    dataDir = "/space/config/paperless";
    mediaDir = "/space/documents";
    consumptionDir = "/space/documents/inbox";

    # use PostgreSQL
    database.createLocally = true;

    settings = {
      PAPERLESS_URL = "https://docs.home";
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_TIME_ZONE = "America/New_York";
    };

    # OIDC config with secret
    environmentFile = config.age.secrets.paperless-env.path;
  };

  # ensure directories exist with correct permissions
  systemd.tmpfiles.rules = [
    "d /space/config/paperless 0750 paperless paperless -"
    "d /space/documents 0750 paperless paperless -"
    "d /space/documents/inbox 0750 paperless paperless -"
  ];

  # ensure Paperless starts after merged filesystem is ready
  systemd.services.paperless-scheduler = {
    after = [ "space.mount" ];
    requires = [ "space.mount" ];
  };

  systemd.services.paperless-consumer = {
    after = [ "space.mount" ];
    requires = [ "space.mount" ];
  };

  systemd.services.paperless-web = {
    after = [ "space.mount" ];
    requires = [ "space.mount" ];
    serviceConfig.UMask = lib.mkForce "0022";
    environment.REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
  };

  # SMB share for mobile uploads to consumption directory
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "map to guest" = "Bad User";
        "guest account" = "paperless";
      };
      scan = {
        path = "/space/documents/inbox";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "yes";
        "force user" = "paperless";
        "force group" = "paperless";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
}
