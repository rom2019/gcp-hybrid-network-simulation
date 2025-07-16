# Gemini API Private Connection 확인 가이드

On-premises 환경에서 Gemini API 호출이 public internet을 통하지 않고 VPN이나 Interconnect를 통해 private 연결되는지 확인하는 방법입니다.

## 빠른 확인 방법

### 1. 간단한 Shell 스크립트 실행
```bash
# On-premises 서버에서 실행
./test_scripts/check_gemini_private_route.sh
```

이 스크립트는 다음을 확인합니다:
- DNS 해석 결과 (Private IP인지 확인)
- 라우팅 경로 (VPN 인터페이스 사용 여부)
- VPN 연결 상태
- 실제 연결 테스트

### 2. 상세한 Python 스크립트 실행
```bash
# 더 자세한 분석이 필요한 경우
python3 test_scripts/verify_gemini_private_connection.py
```

## 수동 확인 명령어

### 1. DNS 확인
```bash
# Gemini API 엔드포인트의 IP 확인
# https://aiplatform.googleapis.com/v1/projects/my-gemini-prod-088dfe15/locations/global/publishers/google/models/gemini-2.5-flash:streamGenerateContent

dig +short aiplatform.googleapis.com
nslookup us-central1-aiplatform.googleapis.com

# Private IP 대역 확인:
# - 10.0.0.0/8
# - 172.16.0.0/12
# - 192.168.0.0/16
# - 199.36.153.0/24 (Google Private Access)
# - 199.36.154.0/23 (Google Private Access)
```

### 2. 라우팅 경로 확인
```bash
# API 엔드포인트까지의 라우팅 확인
ip route get $(dig +short aiplatform.googleapis.com | head -1)

# 전체 라우팅 테이블 확인
ip route show
route -n  # 또는 netstat -rn
```

### 3. VPN 상태 확인
```bash
# IPSec 상태
sudo ipsec status

# OpenVPN 상태
sudo systemctl status openvpn

# WireGuard 상태
sudo wg show

# VPN 인터페이스 확인
ip link show | grep -E "(tun|vpn|vti|ipsec)"
```

### 4. 실시간 트래픽 모니터링
```bash
# Gemini API 트래픽 캡처
sudo tcpdump -i any -n host aiplatform.googleapis.com

# 특정 VPN 인터페이스 모니터링
sudo tcpdump -i tun0 -n port 443

# 연결 상태 확인
ss -tn | grep ':443'
netstat -an | grep ':443'
```

### 5. Traceroute로 경로 추적
```bash
# API 엔드포인트까지의 네트워크 경로 확인
traceroute -n aiplatform.googleapis.com
traceroute -n us-central1-aiplatform.googleapis.com
```

## Private 연결 확인 지표

### ✅ Private 연결 사용 중
- DNS가 Private IP로 해석됨 (10.x, 172.x, 192.168.x)
- DNS가 Google Private Access IP로 해석됨 (199.36.153.x, 199.36.154.x)
- 트래픽이 VPN/tunnel 인터페이스를 통해 라우팅됨
- Traceroute에서 private IP hop이 보임
- tcpdump에서 VPN 인터페이스를 통한 트래픽 확인

### ⚠️ Public Internet 사용 중
- DNS가 일반 public IP로 해석됨
- 트래픽이 기본 게이트웨이를 통해 라우팅됨
- VPN 연결이 없거나 비활성 상태
- Traceroute에서 모든 hop이 public IP

## 문제 해결

### Private 연결이 작동하지 않는 경우

1. **VPN 연결 확인**
   ```bash
   # VPN 터널 상태 확인
   gcloud compute vpn-tunnels list
   gcloud compute vpn-tunnels describe [TUNNEL_NAME]
   ```

2. **DNS 설정 확인**
   ```bash
   # /etc/hosts 확인
   cat /etc/hosts | grep googleapis
   
   # DNS 서버 설정 확인
   cat /etc/resolv.conf
   ```

3. **방화벽 규칙 확인**
   ```bash
   # 아웃바운드 443 포트 허용 확인
   sudo iptables -L -n | grep 443
   ```

4. **Private Google Access 활성화 확인**
   ```bash
   # GCP 콘솔에서 확인 또는
   gcloud compute networks subnets describe [SUBNET_NAME] \
     --region=[REGION] \
     --format="get(privateIpGoogleAccess)"
   ```

## 테스트 시나리오

### 시나리오 1: VPN 연결 전/후 비교
```bash
# VPN 연결 전
./test_scripts/check_gemini_private_route.sh > before_vpn.log

# VPN 연결 후
./test_scripts/check_gemini_private_route.sh > after_vpn.log

# 차이점 비교
diff before_vpn.log after_vpn.log
```

### 시나리오 2: 실제 API 호출 테스트
```bash
# Gemini API 호출하면서 트래픽 모니터링
# Terminal 1:
sudo tcpdump -i any -n -w gemini_traffic.pcap host aiplatform.googleapis.com

# Terminal 2:
python3 test_scripts/test_gemini_api.py

# 캡처된 트래픽 분석
tcpdump -r gemini_traffic.pcap -n
```

## 주의사항

1. 일부 명령어는 sudo 권한이 필요합니다
2. 네트워크 구성에 따라 일부 명령어가 작동하지 않을 수 있습니다
3. Private Google Access를 사용하는 경우에도 DNS 쿼리는 public으로 갈 수 있습니다
4. 실제 데이터 트래픽이 private 경로를 사용하는지가 중요합니다

## 추가 리소스

- [Google Private Google Access](https://cloud.google.com/vpc/docs/private-google-access)
- [VPC Service Controls](https://cloud.google.com/vpc-service-controls/docs)
- [Cloud Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect)
- [Cloud VPN](https://cloud.google.com/network-connectivity/docs/vpn)