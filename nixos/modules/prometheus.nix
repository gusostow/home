{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Prometheus monitoring server
  services.prometheus = {
    enable = true;
    port = 9090;

    # Retention settings
    retentionTime = "30d";

    # Scrape configurations
    scrapeConfigs = [
      # Prometheus self-monitoring
      {
        job_name = "prometheus";
        static_configs = [
          { targets = [ "localhost:9090" ]; }
        ];
      }

      # Node exporter for system metrics
      {
        job_name = "node";
        static_configs = [
          { targets = [ "localhost:9100" ]; }
        ];
      }

      # TODO: Add Tautulli exporter once configured
      # Tautulli doesn't have a built-in NixOS exporter
      # Options: https://github.com/nwalke/tautulli_exporter or similar
    ];

    # Enable exporters
    exporters = {
      # System metrics (CPU, memory, disk, network, etc.)
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
    };
  };
}
