{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Script to generate config with credentials path at runtime
  configScript = pkgs.writeShellScript "unpackerr-config" ''
    cat > /tmp/unpackerr-runtime.conf <<EOF
    interval = "2m"

    [[sonarr]]
    url = "http://localhost:8989"
    api_key = "filepath:${config.age.secrets.sonarr-api-key.path}"
    paths = ["/space/downloads/complete"]
    protocols = "torrent"
    delete_orig = false

    [[radarr]]
    url = "http://localhost:7878"
    api_key = "filepath:${config.age.secrets.radarr-api-key.path}"
    paths = ["/space/downloads/complete"]
    protocols = "torrent"
    delete_orig = false
    EOF

    exec ${pkgs.unpackerr}/bin/unpackerr -c /tmp/unpackerr-runtime.conf
  '';
in
{
  config = lib.mkIf config.services.mediaStack.enable {
    # Create unpackerr user
    users.users.unpackerr = {
      isSystemUser = true;
      group = "media";
      home = "/var/lib/unpackerr";
      createHome = true;
    };

    age.secrets.sonarr-api-key.file = ../../../secrets/sonarr-api-key.age;
    age.secrets.radarr-api-key.file = ../../../secrets/radarr-api-key.age;

    # Unpackerr service with systemd credentials
    systemd.services.unpackerr = {
      description = "Unpackerr - Extracts archives for Sonarr/Radarr";
      after = [
        "network.target"
        "space.mount"
        "qbittorrent.service"
      ];
      requires = [ "space.mount" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "unpackerr";
        Group = "media";
        ExecStart = configScript;
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
