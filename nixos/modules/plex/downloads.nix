{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.services.mediaStack.enable {
    # qBittorrent with web UI
    services.qbittorrent = {
      enable = true;
      webuiPort = 8080;
      openFirewall = true;
      user = "qbittorrent";
      group = "media";
      profileDir = "/space/config/qbittorrent";

      # configure download paths and settings
      serverConfig = {
        LegalNotice.Accepted = true;

        Preferences = {
          Downloads = {
            SavePath = "/space/downloads/complete";
            TempPath = "/space/downloads/incomplete";
            TempPathEnabled = true;
          };

          # webui authentication
          WebUI = {
            Username = "admin";
            # generate with: python3 -c "import hashlib, os, base64; password = input('Password: '); salt = os.urandom(16); dk = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, 100000); print(f'@ByteArray({base64.b64encode(salt).decode()}:{base64.b64encode(dk).decode()})')"
            Password_PBKDF2 = "@ByteArray(NvQWm8rxk05OjW8Sa3isqg==:qAcFy2jgRyOnZjPMUigESXs7CkU9aK341nRC00SOPIb7vRT+Gjkt8NBiWsYKQygVEEfnPN2DSQtNAy4BuaBtIg==)";
          };

          # unlimited active downloads/uploads
          Queueing = {
            MaxActiveDownloads = -1; # -1 = unlimited
            MaxActiveUploads = -1; # -1 = unlimited
            MaxActiveTorrents = -1; # -1 = unlimited
          };
        };
      };
    };

    # Create qbittorrent user
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "media";
    };

    # Ensure qBittorrent starts after /space is mounted
    systemd.services.qbittorrent = {
      after = [ "space.mount" ];
      requires = [ "space.mount" ];

      # Set umask so created files/dirs are group-writable
      serviceConfig.UMask = "0002";
    };
  };
}
