#!/bin/bash
# test_connectivity.sh - 네트워크 연결 테스트 스크립트

echo "=== GCP Hybrid Network Connectivity Test ==="
echo "Date: $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 결과 함수
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# 1. 기본 네트워크 정보 확인
echo "1. Network Information:"
echo "   Hostname: $(hostname)"
echo "   Internal IP: $(hostname -I | awk '{print $1}')"
echo ""

# 2. DNS 확인
echo "2. DNS Resolution Test:"
nslookup googleapis.com > /dev/null 2>&1
test_result $? "googleapis.com DNS resolution"

nslookup restricted.googleapis.com > /dev/null 2>&1
test_result $? "restricted.googleapis.com DNS resolution"
echo ""

# 3. VPN 터널 상태 확인
echo "3. VPN Tunnel Status:"
if command -v gcloud &> /dev/null; then
    # Dev 프로젝트 ID 가져오기
    DEV_PROJECT=$(gcloud config get-value project 2>/dev/null)
    
    if [ ! -z "$DEV_PROJECT" ]; then
        echo "   Checking VPN tunnels in project: $DEV_PROJECT"
        gcloud compute vpn-tunnels list --project=$DEV_PROJECT --format="table(name,status,peerIp)" 2>/dev/null
    else
        echo -e "${YELLOW}   Warning: Project ID not set${NC}"
    fi
else
    echo -e "${YELLOW}   Warning: gcloud CLI not available${NC}"
fi
echo ""

# 4. Prod 네트워크 연결 테스트
echo "4. Production Network Connectivity:"
PROD_SUBNET="10.1.1.0/24"
echo "   Testing connectivity to Prod subnet ($PROD_SUBNET)..."

# Ping 테스트 (예시 IP)
ping -c 3 -W 2 10.1.1.1 > /dev/null 2>&1
test_result $? "Ping to Prod network gateway (10.1.1.1)"
echo ""

# 5. Google APIs 연결 테스트
echo "5. Google APIs Connectivity:"
# Private Google Access 테스트
curl -s -o /dev/null -w "%{http_code}" https://www.googleapis.com/discovery/v1/apis > /tmp/api_test 2>&1
API_STATUS=$(cat /tmp/api_test)
if [ "$API_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Google APIs accessible (HTTP $API_STATUS)${NC}"
else
    echo -e "${RED}✗ Google APIs not accessible (HTTP $API_STATUS)${NC}"
fi

# Restricted VIP 테스트
nc -zv restricted.googleapis.com 443 > /dev/null 2>&1
test_result $? "Restricted Google APIs endpoint (443)"
echo ""

# 6. Gemini API 연결 테스트
echo "6. Gemini API Connectivity Test:"
if command -v gcloud &> /dev/null; then
    # 인증 토큰 확인
    TOKEN=$(gcloud auth print-access-token 2>/dev/null)
    if [ ! -z "$TOKEN" ]; then
        echo "   Testing Gemini API endpoint..."
        
        # Prod 프로젝트 ID (환경 변수나 설정에서 가져오기)
        PROD_PROJECT="${PROD_PROJECT_ID:-gemini-api-prod}"
        
        # API 엔드포인트 테스트
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $TOKEN" \
            "https://us-central1-aiplatform.googleapis.com/v1/projects/$PROD_PROJECT/locations/us-central1" 2>&1)
        
        if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "403" ]; then
            echo -e "${GREEN}✓ Gemini API endpoint reachable (HTTP $RESPONSE)${NC}"
        else
            echo -e "${RED}✗ Gemini API endpoint not reachable (HTTP $RESPONSE)${NC}"
        fi
    else
        echo -e "${YELLOW}   Warning: No auth token available${NC}"
    fi
else
    echo -e "${YELLOW}   Warning: gcloud CLI not available${NC}"
fi
echo ""

# 7. 방화벽 규칙 확인
echo "7. Firewall Rules Check:"
if command -v gcloud &> /dev/null; then
    echo "   Active firewall rules affecting this instance:"
    gcloud compute firewall-rules list --filter="network:dev-vpc" --format="table(name,direction,sourceRanges[].list():label=SRC_RANGES,allowed[].map().firewall_rule().list():label=ALLOW)" 2>/dev/null | head -10
else
    echo -e "${YELLOW}   Warning: gcloud CLI not available${NC}"
fi
echo ""

# 8. 라우팅 테이블 확인
echo "8. Routing Table:"
echo "   Main routes:"
ip route | grep -E "default|10\." | head -5
echo ""

# 9. 성능 테스트 (선택사항)
echo "9. Network Performance (optional):"
echo "   To test bandwidth between networks, run:"
echo "   iperf3 -s (on prod network)"
echo "   iperf3 -c <prod-ip> (from this machine)"
echo ""

# 10. 요약
echo "=== Test Summary ==="
echo "Test completed at: $(date)"
echo ""
echo "Next steps:"
echo "1. If VPN is not connected, check tunnel status and BGP sessions"
echo "2. If API access fails, verify IAM permissions and VPC Service Controls"
echo "3. Run the Gemini test script: python3 /home/debian/test_gemini.py"
echo ""