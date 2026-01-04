{ config, pkgs, lib, ... }:

{
  # dnsmasq for local DNS resolution
  services.dnsmasq = {
    enable = true;

    settings = {
      # Local domain suffix
      domain = "home";

      # Listen on LAN and WireGuard interfaces
      interface = [ "enp34s0" "wg0" ];

      # Don't read /etc/resolv.conf
      no-resolv = true;

      # Upstream DNS servers
      server = [ "8.8.8.8" "8.8.4.4" ];

      # Local hostnames
      address = [
        "/ultan.home/192.168.0.245"
        "/plex.home/192.168.0.245"
        "/requests.home/192.168.0.245"
      ];

      # Don't forward .home queries upstream
      local = "/home/";

      # Expand plain hostnames with .home
      expand-hosts = true;

      # Cache size (default 150)
      cache-size = 1000;

      # Log queries (optional, comment out for less verbosity)
      # log-queries = true;
    };
  };

  # Open DNS port in firewall
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
