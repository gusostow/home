{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.caddy = {
    enable = true;

    # external domains
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
    # internal domains (http:// prefix disables automatic HTTPS)
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
    virtualHosts."http://pi-hole.home" = {
      extraConfig = ''
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
