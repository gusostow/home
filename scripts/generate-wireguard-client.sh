# Script to generate WireGuard client configuration for Ultan VPN
# Usage: ./generate-wireguard-client.sh [--all-traffic] <client-name> <client-ip> [server-pubkey]
#
# Example: ./generate-wireguard-client.sh iphone 10.0.0.3
# Route all traffic: ./generate-wireguard-client.sh --all-traffic iphone 10.0.0.3

# Parse flags
ALL_TRAFFIC=false
if [ "${1:-}" = "--all-traffic" ] || [ "${1:-}" = "-a" ]; then
  ALL_TRAFFIC=true
  shift
fi

CLIENT_NAME="${1:-}"
CLIENT_IP="${2:-}"
SERVER_PUBKEY="${3:-}"

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_IP" ]; then
  echo "Usage: $0 [--all-traffic] <client-name> <client-ip> [server-pubkey]"
  echo ""
  echo "Examples:"
  echo "  $0 iphone 10.0.0.3                      # Route only home network traffic"
  echo "  $0 --all-traffic iphone 10.0.0.3        # Route ALL traffic through VPN"
  exit 1
fi

# Generate client keys
CLIENT_PRIVKEY=$(wg genkey)
CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

SERVER_PUBKEY=$(wg pubkey < /root/secrets/wireguard-private-key)

# Set AllowedIPs based on mode
if [ "$ALL_TRAFFIC" = true ]; then
  ALLOWED_IPS="0.0.0.0/0"
  MODE_DESC="ALL traffic (including internet) routed through VPN"
else
  ALLOWED_IPS="10.0.0.0/24, 192.168.0.0/24"
  MODE_DESC="Only home network traffic routed through VPN"
fi

# Generate client config
cat <<EOF

# WireGuard Client Configuration for $CLIENT_NAME
# $MODE_DESC
# Save this to a file (e.g., $CLIENT_NAME.conf)

[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP/32
DNS = 10.0.0.1

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = vpn.foamer.net:51820
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25

EOF

echo "# ============================================"
echo "# Add this peer to Ultan's WireGuard config:"
echo "# ============================================"
echo ""
echo "Edit modules/wireguard.nix and add this peer:"
echo ""
cat <<EOF
        # $CLIENT_NAME
        {
          publicKey = "$CLIENT_PUBKEY";
          allowedIPs = [ "$CLIENT_IP/32" ];
        }
EOF
echo ""
echo "then rebuild server"
