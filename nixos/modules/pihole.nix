{
  config,
  pkgs,
  lib,
  ...
}:

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
      # Steven Black's unified hosts (base list)
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        type = "block";
        enabled = true;
        description = "Steven Black's unified hosts";
      }
      # OISD Big List - comprehensive blocklist
      {
        url = "https://big.oisd.nl/domainswild";
        type = "block";
        enabled = true;
        description = "OISD Big List";
      }
      # Hagezi's Pro++ List - aggressive ad/tracking blocking
      # commenting out because may be too aggresive.
      # {
      #   url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.plus.txt";
      #   type = "block";
      #   enabled = true;
      #   description = "Hagezi Pro++";
      # }
      # AdGuard DNS filter
      {
        url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
        type = "block";
        enabled = true;
        description = "AdGuard DNS Filter";
      }
    ];

    # Open firewall ports
    openFirewallDNS = true;
    openFirewallWebserver = true;

    # Automatically clean query logs
    queryLogDeleter.enable = true;

    settings = {
      # Web API port (matches pihole-web.ports)
      port = 9797;

      dns = {
        # Local domain for home network
        domain = "home";

        # Upstream DNS servers (Cloudflare)
        upstreams = [
          "1.1.1.1"
          "1.0.0.1"
        ];

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

      # Custom local DNS entries for .home domains
      misc.dnsmasq_lines = [
        "address=/ultan.home/192.168.0.245"
        "address=/ca.home/192.168.0.245"
        "address=/prowlarr.home/192.168.0.245"
        "address=/sonarr.home/192.168.0.245"
        "address=/radarr.home/192.168.0.245"
        "address=/qbittorrent.home/192.168.0.245"
        "address=/pi-hole.home/192.168.0.245"
        "local=/home/"
      ];
    };
  };

  # Disable standalone dnsmasq (Pi-hole uses its own)
  services.dnsmasq.enable = lib.mkForce false;
}
