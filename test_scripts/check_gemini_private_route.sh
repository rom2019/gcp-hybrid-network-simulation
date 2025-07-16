#!/bin/bash

# check_gemini_private_route.sh - Gemini API Private 연결 확인 스크립트
# On-premises에서 실행하여 Gemini API가 private 연결을 사용하는지 확인

echo "========================================"
echo "Gemini API Private Connection Check"
echo "Date: $(date)"
echo "========================================"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. DNS Resolution 확인
echo -e "\n${YELLOW}1. DNS Resolution Check${NC}"
echo "----------------------------------------"

ENDPOINTS=(
    "aiplatform.googleapis.com"
    "us-central1-aiplatform.googleapis.com"
    "generativelanguage.googleapis.com"
)

for endpoint in "${ENDPOINTS[@]}"; do
    echo -e "\n$endpoint:"
    # DNS 조회
    ips=$(dig +short $endpoint 2>/dev/null || nslookup $endpoint 2>/dev/null | grep -A1 "Name:" | grep "Address" | awk '{print $2}')
    
    if [ -z "$ips" ]; then
        echo -e "  ${RED}✗ DNS resolution failed${NC}"
    else
        for ip in $ips; do
            echo -n "  $ip - "
            # Private IP 확인
            if [[ $ip =~ ^10\. ]] || [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] || [[ $ip =~ ^192\.168\. ]]; then
                echo -e "${GREEN}✓ Private IP (VPN/Interconnect)${NC}"
            elif [[ $ip =~ ^199\.36\.15[34]\. ]]; then
                echo -e "${GREEN}✓ Google Private Access IP${NC}"
            else
                echo -e "${YELLOW}⚠ Public IP${NC}"
            fi
        done
    fi
done

# 2. 라우팅 경로 확인
echo -e "\n\n${YELLOW}2. Routing Path Check${NC}"
echo "----------------------------------------"

# aiplatform.googleapis.com의 IP 가져오기
API_IP=$(dig +short aiplatform.googleapis.com | head -1)

if [ ! -z "$API_IP" ]; then
    echo "Checking route to aiplatform.googleapis.com ($API_IP):"
    
    # Linux
    if command -v ip &> /dev/null; then
        route_info=$(ip route get $API_IP 2>/dev/null)
        echo "$route_info"
        
        # VPN 인터페이스 확인
        if echo "$route_info" | grep -qE "(tun|vpn|vti|ipsec)"; then
            echo -e "${GREEN}✓ Traffic routed through VPN interface${NC}"
        elif echo "$route_info" | grep -qE "via (10\.|172\.|192\.168\.)"; then
            echo -e "${GREEN}✓ Traffic routed through private gateway${NC}"
        else
            echo -e "${YELLOW}⚠ Traffic may use public internet${NC}"
        fi
    # macOS
    elif command -v route &> /dev/null; then
        route get $API_IP
    fi
fi

# 3. VPN 연결 상태 확인
echo -e "\n\n${YELLOW}3. VPN Connection Status${NC}"
echo "----------------------------------------"

# IPSec 확인
if command -v ipsec &> /dev/null; then
    if sudo ipsec status 2>/dev/null | grep -q "ESTABLISHED"; then
        echo -e "${GREEN}✓ IPSec connection ESTABLISHED${NC}"
    else
        echo -e "${RED}✗ IPSec not connected${NC}"
    fi
fi

# OpenVPN 확인
if systemctl is-active openvpn &>/dev/null; then
    echo -e "${GREEN}✓ OpenVPN is running${NC}"
fi

# WireGuard 확인
if command -v wg &> /dev/null && sudo wg show &>/dev/null; then
    echo -e "${GREEN}✓ WireGuard is active${NC}"
fi

# VPN 인터페이스 확인
vpn_interfaces=$(ip link show 2>/dev/null | grep -E "(tun|vpn|vti|ipsec)" | awk -F: '{print $2}' | tr -d ' ')
if [ ! -z "$vpn_interfaces" ]; then
    echo -e "\n${GREEN}Active VPN interfaces:${NC}"
    for iface in $vpn_interfaces; do
        echo "  - $iface"
        ip addr show $iface 2>/dev/null | grep "inet " | awk '{print "    IP: " $2}'
    done
fi

# 4. 간단한 연결 테스트
echo -e "\n\n${YELLOW}4. Quick Connection Test${NC}"
echo "----------------------------------------"

# HTTP 헤더 확인
echo "Testing HTTPS connection to Vertex AI:"
response=$(curl -s -I -X GET https://us-central1-aiplatform.googleapis.com/v1/projects 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ HTTPS connection successful${NC}"
    
    # SSL 인증서 정보 확인
    echo -e "\nSSL Certificate info:"
    echo | openssl s_client -connect us-central1-aiplatform.googleapis.com:443 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null | sed 's/^/  /'
else
    echo -e "${RED}✗ Connection failed${NC}"
fi

# 5. 실시간 트래픽 모니터링 명령어 제안
echo -e "\n\n${YELLOW}5. Traffic Monitoring Commands${NC}"
echo "----------------------------------------"
echo "To monitor real-time traffic to Gemini API, use one of these commands:"
echo ""
echo "1. Using tcpdump (requires sudo):"
echo "   ${GREEN}sudo tcpdump -i any -n host aiplatform.googleapis.com${NC}"
echo ""
echo "2. Monitor specific VPN interface:"
if [ ! -z "$vpn_interfaces" ]; then
    for iface in $vpn_interfaces; do
        echo "   ${GREEN}sudo tcpdump -i $iface -n port 443${NC}"
        break
    done
fi
echo ""
echo "3. Check active connections:"
echo "   ${GREEN}ss -tn | grep ':443'${NC}"
echo ""
echo "4. Continuous ping test:"
echo "   ${GREEN}ping -c 10 aiplatform.googleapis.com${NC}"

# 6. 요약
echo -e "\n\n${YELLOW}======== SUMMARY ========${NC}"
echo ""
echo "Private connection indicators:"
echo "✓ DNS resolves to private IP (10.x, 172.x, 192.168.x)"
echo "✓ DNS resolves to Google Private Access IP (199.36.153.x/154.x)"
echo "✓ Traffic routed through VPN/tunnel interface"
echo "✓ Active VPN connection (IPSec/OpenVPN/WireGuard)"
echo ""
echo "Public connection indicators:"
echo "⚠ DNS resolves to public IP"
echo "⚠ Traffic routed through default gateway"
echo "⚠ No active VPN connection"
echo ""
echo -e "${YELLOW}Note:${NC} Run this script on your on-premises machine to verify"
echo "      if Gemini API calls use private connectivity."