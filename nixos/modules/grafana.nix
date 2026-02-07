{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Node Exporter Full dashboard (ID: 1860)
  nodeExporterDashboard = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
    hash = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
  };

  # Loki Logs dashboard (ID: 13639)
  lokiLogsDashboard = pkgs.fetchurl {
    url = "https://grafana.com/api/dashboards/13639/revisions/2/download";
    hash = "sha256-/mJlH0EzTg2ei/Njoqd+OOXQqPdE9JKKwS76j9c2Mtg=";
  };

  dashboardsDir = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${nodeExporterDashboard} $out/node-exporter-full.json
    cp ${lokiLogsDashboard} $out/loki-logs.json
  '';
in
{
  age.secrets.grafana-oidc-secret = {
    file = ../../secrets/grafana-oidc-secret.age;
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://grafana.home";
      };
      "auth.generic_oauth" = {
        enabled = true;
        name = "Keycloak";
        allow_sign_up = true;
        client_id = "grafana";
        client_secret = "$__file{${config.age.secrets.grafana-oidc-secret.path}}";
        scopes = "openid profile email";
        auth_url = "https://idp.home/realms/home/protocol/openid-connect/auth";
        token_url = "https://idp.home/realms/home/protocol/openid-connect/token";
        api_url = "https://idp.home/realms/home/protocol/openid-connect/userinfo";
        # use email as login identifier
        email_attribute_path = "email";
        login_attribute_path = "preferred_username";
        name_attribute_path = "name";
        # grant admin to all OIDC users
        role_attribute_strict = false;
        role_attribute_path = "'Admin'";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = dashboardsDir;
        }
      ];
    };
  };
}
