#!/bin/bash

# VPN Connectivity Diagnostic Script

echo "=== VPN Connectivity Diagnostics ==="
echo
echo "This script will help diagnose VPN connectivity issues between Dev and Prod projects"
echo

# Get project IDs from terraform output or use defaults
DEV_PROJECT=$(terraform output -raw dev_project_id 2>/dev/null || echo "my-onprem-sim-088dfe15")
PROD_PROJECT=$(terraform output -raw prod_project_id 2>/dev/null || echo "my-gemini-prod-088dfe15")
REGION="us-central1"

echo "Dev Project: $DEV_PROJECT"
echo "Prod Project: $PROD_PROJECT"
echo "Region: $REGION"
echo

# Function to check VPN tunnel status
check_vpn_tunnels() {
    local project=$1
    local project_name=$2
    
    echo "=== Checking VPN Tunnels in $project_name Project ==="
    gcloud compute vpn-tunnels list --project=$project --format="table(
        name,
        status,
        peerIp,
        ikeVersion,
        detailedStatus
    )"
    echo
}

# Function to check BGP session status
check_bgp_sessions() {
    local project=$1
    local project_name=$2
    
    echo "=== Checking BGP Sessions in $project_name Project ==="
    # Get routers
    routers=$(gcloud compute routers list --project=$project --regions=$REGION --format="value(name)")
    
    for router in $routers; do
        echo "Router: $router"
        gcloud compute routers get-status $router \
            --project=$project \
            --region=$REGION \
            --format="table(
                result.bgpPeerStatus[].name,
                result.bgpPeerStatus[].status,
                result.bgpPeerStatus[].ipAddress,
                result.bgpPeerStatus[].peerIpAddress,
                result.bgpPeerStatus[].state,
                result.bgpPeerStatus[].uptimeSeconds
            )"
        echo
    done
}

# Function to check routes
check_routes() {
    local project=$1
    local project_name=$2
    
    echo "=== Checking Routes in $project_name Project ==="
    gcloud compute routes list --project=$project --format="table(
        name,
        network,
        destRange,
        nextHopVpnTunnel.scope():label=VPN_TUNNEL,
        priority
    )" | grep -E "(vpn|10\.|NAME)"
    echo
}

# Function to check firewall rules
check_firewall_rules() {
    local project=$1
    local project_name=$2
    
    echo "=== Checking Firewall Rules in $project_name Project ==="
    gcloud compute firewall-rules list --project=$project --format="table(
        name,
        direction,
        priority,
        sourceRanges.list():label=SRC_RANGES,
        allowed[].map().firewall_rule().list():label=ALLOW,
        targetTags.list():label=TARGET_TAGS
    )" | grep -E "(allow|vpn|10\.|NAME)"
    echo
}

# Run diagnostics
echo "1. Checking VPN Tunnel Status..."
echo "================================"
check_vpn_tunnels $DEV_PROJECT "Dev"
check_vpn_tunnels $PROD_PROJECT "Prod"

echo "2. Checking BGP Session Status..."
echo "================================="
check_bgp_sessions $DEV_PROJECT "Dev"
check_bgp_sessions $PROD_PROJECT "Prod"

echo "3. Checking Routes..."
echo "===================="
check_routes $DEV_PROJECT "Dev"
check_routes $PROD_PROJECT "Prod"

echo "4. Checking Firewall Rules..."
echo "============================"
check_firewall_rules $DEV_PROJECT "Dev"
check_firewall_rules $PROD_PROJECT "Prod"

echo "5. Quick Connectivity Tests..."
echo "=============================="
echo "From Dev VM perspective:"
echo "- Dev subnet: 10.0.1.0/24"
echo "- Prod subnet: 10.1.1.0/24"
echo

echo "=== Diagnostic Summary ==="
echo "Check the following:"
echo "1. VPN Tunnels should show 'ESTABLISHED' status"
echo "2. BGP Sessions should show 'Established' state"
echo "3. Routes should exist for cross-VPC communication"
echo "4. Firewall rules should allow traffic between subnets"
echo
echo "Common issues:"
echo "- If tunnels are not ESTABLISHED: Check VPN gateway IPs and shared secret"
echo "- If BGP is not Established: Check BGP peer configuration and IP ranges"
echo "- If routes are missing: BGP might not be advertising routes properly"
echo "- If firewall blocking: Add rules to allow traffic between 10.0.0.0/16 and 10.1.0.0/16"