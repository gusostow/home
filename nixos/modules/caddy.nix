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

  # forward auth snippet for oauth2-proxy
  forwardAuth = ''
    forward_auth localhost:4180 {
      uri /oauth2/auth
      header_up X-Real-IP {remote_host}
      header_up X-Forwarded-Uri {uri}
      copy_headers X-Auth-Request-User X-Auth-Request-Email

      @unauthorized status 401
      handle_response @unauthorized {
        redir https://auth.home/oauth2/start?rd={scheme}://{host}{uri}
      }
    }
  '';

  mkInternalHost = port: {
    extraConfig = ''
      ${internalTls}
      reverse_proxy localhost:${toString port}
    '';
  };

  # internal host with SSO via oauth2-proxy
  mkProtectedHost = port: {
    extraConfig = ''
      ${internalTls}
      ${forwardAuth}
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

    # internal domains with SSO (use step-ca via ACME + oauth2-proxy)
    virtualHosts."tautulli.home" = mkProtectedHost 8181;

    # internal domains without OAuth2-proxy
    virtualHosts."prowlarr.home" = mkInternalHost 9696;
    virtualHosts."sonarr.home" = mkInternalHost 8989;
    virtualHosts."radarr.home" = mkInternalHost 7878;
    virtualHosts."qbittorrent.home" = mkInternalHost 8080;
    virtualHosts."pi-hole.home" = mkInternalHost 9797;
    virtualHosts."grafana.home" = mkInternalHost 3000;
    virtualHosts."idp.home" = mkInternalHost 8180;

    # oauth2-proxy callback endpoint
    virtualHosts."auth.home" = {
      extraConfig = ''
        ${internalTls}
        reverse_proxy localhost:4180
      '';
    };
  };

  # Open HTTP and HTTPS ports
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Caddy needs to resolve local services
  networking.firewall.allowedUDPPorts = [ 53 ];
}
