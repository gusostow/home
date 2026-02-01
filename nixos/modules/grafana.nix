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
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  dashboardsDir = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${nodeExporterDashboard} $out/node-exporter-full.json
  '';
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
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
