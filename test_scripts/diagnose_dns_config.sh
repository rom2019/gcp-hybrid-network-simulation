#!/bin/bash

# diagnose_dns_config.sh - Diagnose DNS configuration issues

set -e

echo "=== DNS Configuration Diagnosis ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get project IDs
DEV_PROJECT=$(terraform output -raw dev_project_id 2>/dev/null || echo "")
PROD_PROJECT=$(terraform output -raw prod_project_id 2>/dev/null || echo "")

if [ -z "$DEV_PROJECT" ] || [ -z "$PROD_PROJECT" ]; then
    echo -e "${RED}Error: Could not get project IDs${NC}"
    exit 1
fi

echo "Dev Project: $DEV_PROJECT"
echo "Prod Project: $PROD_PROJECT"
echo ""

# 1. Check DNS policies
echo -e "${YELLOW}1. Checking DNS Policies...${NC}"

echo "  Dev Project DNS Policy:"
gcloud dns policies list --project=$DEV_PROJECT --format="table(name,enableInboundForwarding,networks[].networkUrl:label=NETWORK)" 2>/dev/null || echo "    No policies found"

echo ""
echo "  Prod Project DNS Policy:"
gcloud dns policies list --project=$PROD_PROJECT --format="table(name,enableInboundForwarding,networks[].networkUrl:label=NETWORK)" 2>/dev/null || echo "    No policies found"

# 2. Check DNS zones
echo ""
echo -e "${YELLOW}2. Checking DNS Zones...${NC}"

echo "  Dev Project DNS Zones:"
gcloud dns managed-zones list --project=$DEV_PROJECT --format="table(name,dnsName,visibility)" 2>/dev/null || echo "    No zones found"

echo ""
echo "  Prod Project DNS Zones:"
gcloud dns managed-zones list --project=$PROD_PROJECT --format="table(name,dnsName,visibility)" 2>/dev/null || echo "    No zones found"

# 3. Check specific zone details
echo ""
echo -e "${YELLOW}3. Checking googleapis.com zone in Prod...${NC}"
gcloud dns managed-zones describe googleapis-private-zone --project=$PROD_PROJECT 2>/dev/null || echo "  Zone not found"

echo ""
echo -e "${YELLOW}4. Checking forwarding zone in Dev...${NC}"
gcloud dns managed-zones describe googleapis-forwarding-zone --project=$DEV_PROJECT 2>/dev/null || echo "  Zone not found"

# 4. Check DNS records in private zone
echo ""
echo -e "${YELLOW}5. Checking DNS records in private zone...${NC}"
gcloud dns record-sets list --zone=googleapis-private-zone --project=$PROD_PROJECT 2>/dev/null || echo "  No records found"

# 5. Check VM DNS configuration
echo ""
echo -e "${YELLOW}6. Checking VM DNS configuration...${NC}"
echo "  Running on Dev VM:"
gcloud compute ssh dev-workstation \
    --project=$DEV_PROJECT \
    --zone=us-central1-a \
    --command="cat /etc/resolv.conf" 2>/dev/null || echo "  Could not check VM DNS config"

# 6. Check metadata server
echo ""
echo -e "${YELLOW}7. Checking if VM can reach metadata server...${NC}"
gcloud compute ssh dev-workstation \
    --project=$DEV_PROJECT \
    --zone=us-central1-a \
    --command="curl -s -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/dns-servers" 2>/dev/null || echo "  Could not check metadata"

# 7. Test direct DNS query to Cloud DNS
echo ""
echo -e "${YELLOW}8. Testing DNS resolution directly...${NC}"
echo "  Testing from Dev VM with different DNS servers:"

# Test with metadata server
echo -n "  169.254.169.254: "
gcloud compute ssh dev-workstation \
    --project=$DEV_PROJECT \
    --zone=us-central1-a \
    --command="dig @169.254.169.254 +short us-central1-aiplatform.googleapis.com" 2>/dev/null || echo "Failed"

# Test with Google Public DNS
echo -n "  8.8.8.8 (Google Public): "
gcloud compute ssh dev-workstation \
    --project=$DEV_PROJECT \
    --zone=us-central1-a \
    --command="dig @8.8.8.8 +short us-central1-aiplatform.googleapis.com" 2>/dev/null || echo "Failed"

# 8. Check VPN status
echo ""
echo -e "${YELLOW}9. Checking VPN tunnel status...${NC}"
gcloud compute vpn-tunnels list --project=$DEV_PROJECT --format="table(name,status,peerIp)" 2>/dev/null || echo "  No VPN tunnels found"

echo ""
echo "=== Diagnosis Complete ==="
echo ""
echo "Common issues:"
echo "1. DNS policies not properly attached to networks"
echo "2. Forwarding zone not configured correctly"
echo "3. VPN tunnel down (required for DNS forwarding)"
echo "4. Firewall blocking DNS traffic"