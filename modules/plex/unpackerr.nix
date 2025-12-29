{ config, pkgs, lib, ... }:

let
  # Script to generate config with credentials at runtime
  configScript = pkgs.writeShellScript "unpackerr-config" ''
    cat > /tmp/unpackerr-runtime.conf <<EOF
    [[sonarr]]
    url = "http://localhost:8989"
    api_key = "$(cat $CREDENTIALS_DIRECTORY/sonarr-key)"
    paths = ["/space/downloads/complete"]
    protocols = "torrent"
    delete_orig = false

    [[radarr]]
    url = "http://localhost:7878"
    api_key = "$(cat $CREDENTIALS_DIRECTORY/radarr-key)"
    paths = ["/space/downloads/complete"]
    protocols = "torrent"
    delete_orig = false

    [interval]
    check_interval = "2m"
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

    # Unpackerr service with systemd credentials
    systemd.services.unpackerr = {
      description = "Unpackerr - Extracts archives for Sonarr/Radarr";
      after = [ "network.target" "space.mount" "qbittorrent.service" ];
      requires = [ "space.mount" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "unpackerr";
        Group = "media";
        ExecStart = configScript;
        Restart = "on-failure";
        RestartSec = "10s";

        # Load API keys from files on the server (not in git)
        LoadCredential = [
          "sonarr-key:/root/secrets/sonarr-api-key"
          "radarr-key:/root/secrets/radarr-api-key"
        ];
      };
    };
  };
}
