{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Script to export AMD GPU metrics from amdgpu_top to Prometheus textfile format
  amdgpuMetricsScript = pkgs.writeShellScript "amdgpu-metrics" ''
    set -euo pipefail
    OUTPUT_FILE="/var/lib/prometheus-node-exporter/amdgpu.prom"
    TMP_FILE="$OUTPUT_FILE.tmp"

    # Get JSON from amdgpu_top (single snapshot)
    JSON=$(${pkgs.amdgpu_top}/bin/amdgpu_top --json -n 1 2>/dev/null || echo "{}")

    # Parse JSON and output Prometheus metrics
    ${pkgs.jq}/bin/jq -r '
      .devices[]? |
      .Info as $info |
      .gpu_metrics as $m |
      "# HELP amdgpu_temperature_edge GPU edge temperature in celsius",
      "# TYPE amdgpu_temperature_edge gauge",
      "amdgpu_temperature_edge{gpu=\"\($info.DeviceName // "unknown")\"} \($m.Temperature.edge // 0)",
      "# HELP amdgpu_temperature_hotspot GPU hotspot temperature in celsius",
      "# TYPE amdgpu_temperature_hotspot gauge",
      "amdgpu_temperature_hotspot{gpu=\"\($info.DeviceName // "unknown")\"} \($m.Temperature.hotspot // 0)",
      "# HELP amdgpu_temperature_mem GPU memory temperature in celsius",
      "# TYPE amdgpu_temperature_mem gauge",
      "amdgpu_temperature_mem{gpu=\"\($info.DeviceName // "unknown")\"} \($m.Temperature.mem // 0)",
      "# HELP amdgpu_power_watts Current GPU power draw in watts",
      "# TYPE amdgpu_power_watts gauge",
      "amdgpu_power_watts{gpu=\"\($info.DeviceName // "unknown")\"} \($m.SocketPower // 0)",
      "# HELP amdgpu_gfx_activity GPU graphics activity percentage",
      "# TYPE amdgpu_gfx_activity gauge",
      "amdgpu_gfx_activity{gpu=\"\($info.DeviceName // "unknown")\"} \($m.GfxActivity // 0)",
      "# HELP amdgpu_umc_activity GPU memory controller activity percentage",
      "# TYPE amdgpu_umc_activity gauge",
      "amdgpu_umc_activity{gpu=\"\($info.DeviceName // "unknown")\"} \($m.UmcActivity // 0)",
      "# HELP amdgpu_vram_used_mb VRAM used in megabytes",
      "# TYPE amdgpu_vram_used_mb gauge",
      "amdgpu_vram_used_mb{gpu=\"\($info.DeviceName // "unknown")\"} \(($m.VRAM.used // 0) / 1048576)",
      "# HELP amdgpu_vram_total_mb Total VRAM in megabytes",
      "# TYPE amdgpu_vram_total_mb gauge",
      "amdgpu_vram_total_mb{gpu=\"\($info.DeviceName // "unknown")\"} \(($m.VRAM.total // 0) / 1048576)",
      "# HELP amdgpu_gfx_clock_mhz Current graphics clock in MHz",
      "# TYPE amdgpu_gfx_clock_mhz gauge",
      "amdgpu_gfx_clock_mhz{gpu=\"\($info.DeviceName // "unknown")\"} \($m.CurrentGfxclk // 0)",
      "# HELP amdgpu_mem_clock_mhz Current memory clock in MHz",
      "# TYPE amdgpu_mem_clock_mhz gauge",
      "amdgpu_mem_clock_mhz{gpu=\"\($info.DeviceName // "unknown")\"} \($m.CurrentUclk // 0)"
    ' <<< "$JSON" > "$TMP_FILE"

    # Atomic move to avoid partial reads
    mv "$TMP_FILE" "$OUTPUT_FILE"
  '';
in
{
  # Create textfile collector directory (world-readable, root-owned)
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus-node-exporter 0777 root root -"
  ];

  # Timer to run amdgpu metrics collection every 15 seconds
  systemd.services.amdgpu-metrics = {
    description = "Export AMD GPU metrics for Prometheus";
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = amdgpuMetricsScript;
    };
  };

  systemd.timers.amdgpu-metrics = {
    description = "Run AMD GPU metrics exporter";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10s";
      OnUnitActiveSec = "15s";
    };
  };

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
          "textfile"
          "pressure"
          "diskstats"
          "filesystem"
        ];
        extraFlags = [
          "--collector.textfile.directory=/var/lib/prometheus-node-exporter"
        ];
      };
    };
  };
}
