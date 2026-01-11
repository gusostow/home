{ config, pkgs, lib, ... }:

{
  # WireGuard VPN server for remote access to home network
  # VPN clients will use Pi-hole for DNS (ad-blocking + local .home domains)
  networking.wireguard.interfaces = {
    wg0 = {
      # WireGuard listens on this UDP port
      listenPort = 51820;

      # VPN subnet - clients will get IPs in 10.0.0.0/24
      # Server IP is 10.0.0.1 (also the DNS server via Pi-hole)
      ips = [ "10.0.0.1/24" ];

      # Server private key - generate with: wg genkey
      # Store in /root/secrets/wireguard-private-key
      privateKeyFile = "/root/secrets/wireguard-private-key";

      # Enable IP forwarding for VPN clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o enp34s0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o enp34s0 -j MASQUERADE
      '';

      # Peers (VPN clients) - add one section per device
      # Client configs should include: DNS = 10.0.0.1 (to use Pi-hole)
      peers = [
        # macbook
        {
          # Client public key - get from client with: wg pubkey < client-private-key
          publicKey = "f5FY+HEulPxfgs1BQkluqqhOJHIkx/WFuiqF1NnUhSs=";
          # Allow this client to use the VPN IP and access your home network
          allowedIPs = [ "10.0.0.2/32" ];
        }
        # aostow-iphone
        {
          publicKey = "+7rQnZFr1kCZcMv+qdDoqhfZGLD0Q9ws5t8f3ZOMEgo=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
        # aostow-iphone-alltraffic
        {
          publicKey = "gTcVG6UkVrbB5yXMPZQZRPqraSpL6sVvh+jAmwiVClU=";
          allowedIPs = [ "10.0.0.4/32" ];
        }
      ];
    };
  };

  # Enable IP forwarding (required for VPN routing)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Open WireGuard port in firewall
  networking.firewall.allowedUDPPorts = [ 51820 ];
}
