{
  config,
  pkgs,
  lib,
  ...
}:

let
  internalTls = ''
    tls {
      ca https://localhost:8443/acme/acme/directory
      ca_root ${./ca/root/ca.crt}
    }
  '';

  mkInternalHost = port: {
    extraConfig = ''
      ${internalTls}
      reverse_proxy localhost:${toString port}
    '';
  };
in
{
  services.caddy = {
    enable = true;

    # external domains (use Let's Encrypt)
    virtualHosts."plex.foamer.net".extraConfig = "reverse_proxy localhost:32400";
    virtualHosts."requests.foamer.net".extraConfig = "reverse_proxy localhost:5055";

    # serve root CA cert over HTTP for device installation
    virtualHosts."http://ca.home".extraConfig = ''
      rewrite * /ca.cer
      root * ${./ca/root}
      header Content-Type application/x-x509-ca-cert
      file_server
    '';

    # internal domains (use step-ca via ACME)
    virtualHosts."prowlarr.home" = mkInternalHost 9696;
    virtualHosts."sonarr.home" = mkInternalHost 8989;
    virtualHosts."radarr.home" = mkInternalHost 7878;
    virtualHosts."qbittorrent.home" = mkInternalHost 8080;
    virtualHosts."pi-hole.home" = mkInternalHost 9797;
  };

  # Open HTTP and HTTPS ports
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Caddy needs to resolve local services
  networking.firewall.allowedUDPPorts = [ 53 ];
}
