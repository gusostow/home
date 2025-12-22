{ config, pkgs, lib, ... }:

let
  ddnsScript = pkgs.writeScriptBin "ddns-update" (builtins.readFile ./ddns-update.sh);
in
{
  # DDNS updater for Route53
  systemd.services.ddns-update = {
    description = "Update Route53 DNS records with current public IP";
    path = with pkgs; [ awscli2 curl dnsutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ddnsScript}/bin/ddns-update";
    };
    environment = {
      # Use ddclient profile from /root/.aws/credentials
      AWS_PROFILE = "ddclient";
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
