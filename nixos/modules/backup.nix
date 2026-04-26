{
  config,
  pkgs,
  lib,
  ...
}:

let
  backupScript = pkgs.writeShellApplication {
    name = "s3-backup";
    runtimeInputs = with pkgs; [
      rclone
      coreutils
    ];
    text = builtins.readFile ../../scripts/s3-backup.sh;
  };
in
{
  age.secrets.backup-aws-creds = {
    file = ../../secrets/backup-aws-creds.age;
    owner = "backup";
    group = "backup";
  };

  # create backup user and group
  users.groups.backup = { };

  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    # add to immich group to read /space/immich
    extraGroups = [
      "immich"
      "aostow"
    ];
    description = "Backup service user";
  };

  # s3 backup service
  systemd.services.s3-backup = {
    description = "Backup files to S3 using rclone";
    serviceConfig = {
      Type = "oneshot";
      User = "backup";
      Group = "backup";
      ExecStart = "${backupScript}/bin/s3-backup";
      # restart on failure after 5 minutes
      Restart = "on-failure";
      RestartSec = "5min";
    };
    environment = {
      AWS_CONFIG_FILE = config.age.secrets.backup-aws-creds.path;
      AWS_PROFILE = "backup";
    };
    # ensure filesystems are mounted
    after = [
      "space.mount"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
  };

  # run backup daily at 2am
  systemd.timers.s3-backup = {
    description = "Daily S3 backup timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [ rclone ];
}
