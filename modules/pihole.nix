{ config, pkgs, lib, ... }:

{
  # Pi-hole web interface
  services.pihole-web = {
    enable = true;
    ports = [ 9797 ];
  };

  # Pi-hole DNS server with ad-blocking
  services.pihole-ftl = {
    enable = true;

    # Ad-blocking lists
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        type = "block";
        enabled = true;
        description = "Steven Black's unified hosts";
      }
    ];

    # Open firewall ports
    openFirewallDNS = true;
    openFirewallWebserver = true;

    # Automatically clean query logs
    queryLogDeleter.enable = true;

    settings = {
      # Web API port (matches pihole-web.ports)
      port = 8080;

      dns = {
        # Local domain for home network
        domain = "home";

        # Upstream DNS servers (Cloudflare)
        upstreams = [ "1.1.1.1" "1.0.0.1" ];

        # Listen on LAN and WireGuard interfaces
        # Pi-hole will handle DNS for both local network and VPN clients
        listeningMode = "all";
      };

      webserver = {
        api = {
          # Set password with: pihole -a -p
          # Or generate hash with: echo -n "password" | sha256sum | awk '{printf "%s",$1 }' | sha256sum
          # For now, password must be set via web UI or CLI after first boot
        };
      };

      # DHCP disabled - router handles DHCP
      dhcp = {
        active = false;
      };
    };
  };

  # Custom local DNS entries for .home domains
  # Pi-hole uses dnsmasq internally, so we can add custom dnsmasq config
  environment.etc."dnsmasq.d/custom-hosts.conf".text = ''
    # Local hostnames
    address=/ultan.home/192.168.0.245
    address=/plex.home/192.168.0.245
    address=/requests.home/192.168.0.245

    # Don't forward .home queries upstream
    local=/home/
  '';

  # Disable standalone dnsmasq (Pi-hole uses its own)
  services.dnsmasq.enable = lib.mkForce false;
}
