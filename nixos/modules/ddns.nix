{
  config,
  pkgs,
  lib,
  ...
}:

let
  ddnsScript = pkgs.writeShellApplication {
    name = "ddns-update";
    runtimeInputs = with pkgs; [
      awscli2
      curl
      dnsutils
    ];
    text = builtins.readFile ./ddns-update.sh;
  };
in
{
  age.secrets.ddns-aws-creds.file = ../../secrets/ddns-aws-creds.age;

  # DDNS updater for Route53
  systemd.services.ddns-update = {
    description = "Update Route53 DNS records with current public IP";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ddnsScript}/bin/ddns-update";
    };
    environment = {
      # ddclient profile in decrypted AWS credentials
      AWS_PROFILE = "ddclient";
      AWS_CONFIG_FILE = config.age.secrets.ddns-aws-creds.path;
    };
  };

  # Run every 5 minutes
  systemd.timers.ddns-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
    };
  };

  environment.systemPackages = with pkgs; [ awscli2 ];
}
