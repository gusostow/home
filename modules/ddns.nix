{ config, pkgs, lib, ... }:

{
  services.ddclient = {
    enable = true;
    protocol = "route53";
    zone = "foamer.net";
    domains = [ "plex.foamer.net" "requests.foamer.net" ];
    interval = "5min";
  };

  # Configure ddclient to use the "ddclient" AWS profile
  systemd.services.ddclient.environment = {
    # manually saved in /root/.aws/credentials
    AWS_PROFILE = "ddclient";
  };
}
