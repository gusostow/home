set -euo pipefail

HOSTED_ZONE_ID="Z0419929NHM3F17LIKCL"
DOMAINS=("plex.foamer.net" "requests.foamer.net" "vpn.foamer.net")

# Get current public IP
CURRENT_IP=$(curl -s ifconfig.me)

if [ -z "$CURRENT_IP" ]; then
  echo "Failed to get public IP"
  exit 1
fi

echo "Current public IP: $CURRENT_IP"

# Update each domain
for DOMAIN in "${DOMAINS[@]}"; do
  # Get current DNS record
  DNS_IP=$(dig +short "$DOMAIN" @8.8.8.8 | tail -n1)

  if [ "$DNS_IP" = "$CURRENT_IP" ]; then
    echo "$DOMAIN already points to $CURRENT_IP"
  else
    echo "Updating $DOMAIN from $DNS_IP to $CURRENT_IP"

    # Create change batch JSON
    CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$DOMAIN",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "$CURRENT_IP"}]
    }
  }]
}
EOF
    )

    # Update Route53
    aws route53 change-resource-record-sets \
      --hosted-zone-id "$HOSTED_ZONE_ID" \
      --change-batch "$CHANGE_BATCH"

    echo "Updated $DOMAIN to $CURRENT_IP"
  fi
done
