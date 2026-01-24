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
    # internal domains
    virtualHosts."prowlarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:9696
      '';
    };
    virtualHosts."sonarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:8989
      '';
    };
    virtualHosts."radarr.home" = {
      extraConfig = ''
        reverse_proxy localhost:7878
      '';
    };
    virtualHosts."qbittorrent.home" = {
      extraConfig = ''
        reverse_proxy localhost:8080
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
