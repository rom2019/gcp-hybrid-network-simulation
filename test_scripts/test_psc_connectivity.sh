#!/bin/bash

# Test script for Private Service Connect connectivity to Google APIs

echo "=== Testing Private Service Connect Configuration ==="
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check DNS resolution
check_dns() {
    local domain=$1
    echo -e "${YELLOW}Checking DNS resolution for $domain...${NC}"
    
    result=$(nslookup $domain 2>&1)
    if echo "$result" | grep -q "10.0.1.10"; then
        echo -e "${GREEN}✓ $domain resolves to PSC endpoint${NC}"
        echo "$result" | grep -A 2 "Name:"
    else
        echo -e "${RED}✗ $domain does not resolve to PSC endpoint${NC}"
        echo "$result"
    fi
    echo
}

# Function to test HTTPS connectivity
test_https() {
    local url=$1
    echo -e "${YELLOW}Testing HTTPS connectivity to $url...${NC}"
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 $url | grep -q "200\|404"; then
        echo -e "${GREEN}✓ Successfully connected to $url${NC}"
        curl -I $url 2>&1 | head -n 5
    else
        echo -e "${RED}✗ Failed to connect to $url${NC}"
        curl -v $url 2>&1 | tail -n 20
    fi
    echo
}

# Function to test API call
test_api_call() {
    echo -e "${YELLOW}Testing AI Platform API call...${NC}"
    
    # Get access token
    TOKEN=$(gcloud auth print-access-token 2>/dev/null)
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}✗ Failed to get access token. Please run 'gcloud auth login'${NC}"
        return
    fi
    
    # Get project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}✗ No project set. Please run 'gcloud config set project PROJECT_ID'${NC}"
        return
    fi
    
    # Test API call
    response=$(curl -s -X GET \
        -H "Authorization: Bearer $TOKEN" \
        "https://aiplatform.googleapis.com/v1/projects/$PROJECT_ID/locations/global" 2>&1)
    
    if echo "$response" | grep -q "locations"; then
        echo -e "${GREEN}✓ Successfully called AI Platform API${NC}"
        echo "$response" | python3 -m json.tool 2>/dev/null | head -n 10
    else
        echo -e "${RED}✗ Failed to call AI Platform API${NC}"
        echo "$response"
    fi
    echo
}

# Main tests
echo "1. DNS Resolution Tests"
echo "======================="
check_dns "googleapis.com"
check_dns "aiplatform.googleapis.com"
check_dns "storage.googleapis.com"

echo "2. HTTPS Connectivity Tests"
echo "==========================="
test_https "https://googleapis.com"
test_https "https://aiplatform.googleapis.com"

echo "3. API Call Test"
echo "================"
test_api_call

echo "4. Network Route Check"
echo "======================"
echo -e "${YELLOW}Checking routing table...${NC}"
ip route | grep "10.0.1.10"
echo

echo "5. PSC Endpoint Status"
echo "======================"
echo -e "${YELLOW}Checking if PSC endpoints are reachable...${NC}"
for ip in 10.0.1.100 10.0.1.101; do
    if ping -c 1 -W 2 $ip > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PSC endpoint $ip is reachable${NC}"
    else
        echo -e "${RED}✗ PSC endpoint $ip is not reachable${NC}"
    fi
done

echo
echo "=== Test Complete ==="