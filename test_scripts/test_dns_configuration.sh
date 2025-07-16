#!/bin/bash

# test_dns_configuration.sh - Test DNS configuration for private Google API access

set -e

echo "=== DNS Configuration Test Script ==="
echo "This script tests if DNS is properly configured for private Google API access"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get project IDs from terraform output
echo "Getting project information..."
DEV_PROJECT=$(terraform output -raw dev_project_id 2>/dev/null || echo "")
PROD_PROJECT=$(terraform output -raw prod_project_id 2>/dev/null || echo "")

if [ -z "$DEV_PROJECT" ] || [ -z "$PROD_PROJECT" ]; then
    echo -e "${RED}Error: Could not get project IDs from terraform output${NC}"
    echo "Please run 'terraform apply' first"
    exit 1
fi

echo "Dev Project: $DEV_PROJECT"
echo "Prod Project: $PROD_PROJECT"
echo ""

# Function to check DNS resolution
check_dns_resolution() {
    local vm_name=$1
    local project=$2
    local zone=$3
    
    echo -e "${YELLOW}Checking DNS resolution from $vm_name in $project...${NC}"
    
    # Test DNS resolution for various Google APIs
    local apis=(
        "us-central1-aiplatform.googleapis.com"
        "aiplatform.googleapis.com"
        "storage.googleapis.com"
        "compute.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        echo -n "  Resolving $api: "
        
        # Run nslookup on the VM
        result=$(gcloud compute ssh $vm_name \
            --project=$project \
            --zone=$zone \
            --command="nslookup $api 2>&1" 2>/dev/null || echo "FAILED")
        
        if echo "$result" | grep -q "199.36.153"; then
            echo -e "${GREEN}✓ Resolves to private IP${NC}"
            echo "    $(echo "$result" | grep -A1 "Address:" | tail -1)"
        elif echo "$result" | grep -q "Address:"; then
            echo -e "${RED}✗ Resolves to public IP${NC}"
            echo "    $(echo "$result" | grep -A1 "Address:" | tail -1)"
        else
            echo -e "${RED}✗ Failed to resolve${NC}"
        fi
    done
    echo ""
}

# Function to check DNS forwarder IPs
check_dns_forwarders() {
    echo -e "${YELLOW}Checking DNS forwarder configuration...${NC}"
    
    # Get inbound forwarder IPs from Prod project
    echo "  Getting inbound forwarder IPs from Prod project..."
    forwarder_ips=$(gcloud dns policies describe prod-inbound-dns-policy \
        --project=$PROD_PROJECT \
        --format="value(networks[0].inboundForwarderAddresses[].ipv4Address)" 2>/dev/null || echo "")
    
    if [ -n "$forwarder_ips" ]; then
        echo -e "  ${GREEN}✓ Inbound forwarder IPs found:${NC}"
        echo "$forwarder_ips" | while read ip; do
            echo "    - $ip"
        done
    else
        echo -e "  ${RED}✗ No inbound forwarder IPs found${NC}"
    fi
    
    # Check outbound policy in Dev project
    echo ""
    echo "  Checking outbound DNS policy in Dev project..."
    outbound_policy=$(gcloud dns policies describe dev-outbound-dns-policy \
        --project=$DEV_PROJECT \
        --format="value(alternativeNameServerConfig.targetNameServers[0].ipv4Address)" 2>/dev/null || echo "")
    
    if [ -n "$outbound_policy" ]; then
        echo -e "  ${GREEN}✓ Outbound DNS policy configured${NC}"
        echo "    Target nameserver: $outbound_policy"
    else
        echo -e "  ${RED}✗ Outbound DNS policy not found${NC}"
    fi
    echo ""
}

# Function to test connectivity to private.googleapis.com
test_private_endpoint() {
    local vm_name=$1
    local project=$2
    local zone=$3
    
    echo -e "${YELLOW}Testing connectivity to private.googleapis.com from $vm_name...${NC}"
    
    # Test connectivity to private Google API endpoints
    local private_ips=("199.36.153.8" "199.36.153.9" "199.36.153.10" "199.36.153.11")
    
    for ip in "${private_ips[@]}"; do
        echo -n "  Testing connectivity to $ip: "
        
        # Use curl to test HTTPS connectivity
        result=$(gcloud compute ssh $vm_name \
            --project=$project \
            --zone=$zone \
            --command="curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 https://$ip 2>&1" 2>/dev/null || echo "FAILED")
        
        if [ "$result" = "404" ] || [ "$result" = "403" ]; then
            echo -e "${GREEN}✓ Reachable (HTTP $result)${NC}"
        elif [ "$result" = "FAILED" ]; then
            echo -e "${RED}✗ Connection failed${NC}"
        else
            echo -e "${YELLOW}? HTTP $result${NC}"
        fi
    done
    echo ""
}

# Function to trace route to googleapis.com
trace_route() {
    local vm_name=$1
    local project=$2
    local zone=$3
    
    echo -e "${YELLOW}Tracing route to us-central1-aiplatform.googleapis.com from $vm_name...${NC}"
    
    # Run traceroute (limited to 10 hops)
    echo "  Running traceroute (first 5 hops)..."
    gcloud compute ssh $vm_name \
        --project=$project \
        --zone=$zone \
        --command="sudo traceroute -m 5 -n us-central1-aiplatform.googleapis.com 2>&1" 2>/dev/null || echo "  Traceroute failed"
    
    echo ""
}

# Main execution
echo "=== Starting DNS Configuration Tests ==="
echo ""

# 1. Check DNS forwarder configuration
check_dns_forwarders

# 2. Check DNS resolution from Dev VM
check_dns_resolution "dev-workstation" "$DEV_PROJECT" "us-central1-a"

# 3. Test connectivity to private endpoints
test_private_endpoint "dev-workstation" "$DEV_PROJECT" "us-central1-a"

# 4. Trace route to verify traffic path
trace_route "dev-workstation" "$DEV_PROJECT" "us-central1-a"

# Summary
echo "=== Test Summary ==="
echo ""
echo "If all tests passed, your DNS configuration is working correctly and:"
echo "1. googleapis.com domains resolve to private IPs (199.36.153.8-11)"
echo "2. Traffic to Google APIs goes through the VPN tunnel"
echo "3. API calls will use private endpoints instead of public internet"
echo ""
echo "If any tests failed, check:"
echo "1. DNS policies are correctly configured in both projects"
echo "2. Firewall rules allow DNS traffic (UDP/TCP port 53)"
echo "3. VPN tunnel is up and routes are properly configured"
echo "4. The VM has the correct DNS settings"