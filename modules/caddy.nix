{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

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
  };

  # Open HTTP and HTTPS ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Caddy needs to resolve local services
  networking.firewall.allowedUDPPorts = [ 53 ];
}
