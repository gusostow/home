{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.caddy = {
    enable = true;

    # external domains (use Let's Encrypt)
    virtualHosts."plex.foamer.net" = {
      extraConfig = ''
        reverse_proxy localhost:32400
      '';
    };
    virtualHosts."requests.foamer.net" = {
      extraConfig = ''
        reverse_proxy localhost:5055
      '';
    };

    # internal domains (use step-ca via ACME)
    virtualHosts."http://prowlarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:9696
      '';
    };
    virtualHosts."http://sonarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:8989
      '';
    };
    virtualHosts."http://radarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:7878
      '';
    };
    virtualHosts."http://qbittorrent.home" = {
      extraConfig = ''
        reverse_proxy localhost:8080
      '';
    };
    virtualHosts."pi-hole.home" = {
      extraConfig = ''
        tls {
          ca https://localhost:8443/acme/acme/directory
          ca_root ${../modules/ca/root/ca.crt}
        }
        reverse_proxy localhost:9797
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
