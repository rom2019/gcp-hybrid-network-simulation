#!/bin/bash

# Script to apply the DNS API fix to your Terraform infrastructure

echo "=== Applying Cloud DNS API Fix ==="
echo "Timestamp: $(date)"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}✅ DNS API has been added to main.tf${NC}"
echo ""

echo "Next steps to apply the fix:"
echo ""

echo -e "${YELLOW}1. First, run terraform plan to see the changes:${NC}"
echo "   terraform plan"
echo ""

echo -e "${YELLOW}2. If the plan looks good, apply the changes:${NC}"
echo "   terraform apply"
echo ""

echo "Expected changes:"
echo "  - Cloud DNS API (dns.googleapis.com) will be enabled for the dev project"
echo "  - This will allow the DNS managed zone and records to be created successfully"
echo ""

echo -e "${YELLOW}Alternative: Manual API enablement (if needed immediately):${NC}"
echo "   gcloud services enable dns.googleapis.com --project=my-onprem-sim-088dfe15"
echo ""

echo "After applying:"
echo "  - The DNS managed zone 'googleapis-zone' will be created"
echo "  - Private DNS records for googleapis.com will be configured"
echo "  - This enables Private Google Access for your on-premises simulation"
echo ""

echo -e "${GREEN}The fix has been implemented in main.tf at line 58.${NC}"