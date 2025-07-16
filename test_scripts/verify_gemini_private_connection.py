#!/usr/bin/env python3
"""
verify_gemini_private_connection.py - Gemini API Private 연결 검증 스크립트
On-premises에서 Gemini API 호출이 VPN/Interconnect를 통해 이루어지는지 확인
"""

import os
import sys
import json
import time
import socket
import subprocess
import traceback
from datetime import datetime

def run_command(cmd):
    """명령어 실행 및 결과 반환"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", "Command timed out", 1
    except Exception as e:
        return "", str(e), 1

def check_dns_resolution():
    """DNS 해석 확인"""
    print("\n1. DNS Resolution Check")
    print("=" * 60)
    
    endpoints = [
        "aiplatform.googleapis.com",
        "us-central1-aiplatform.googleapis.com",
        "generativelanguage.googleapis.com",
        "*.googleapis.com"
    ]
    
    for endpoint in endpoints:
        if "*" in endpoint:
            endpoint = endpoint.replace("*", "test")
        
        try:
            # DNS 조회
            ips = socket.gethostbyname_ex(endpoint)[2]
            print(f"\n{endpoint}:")
            for ip in ips:
                print(f"  - {ip}")
                
                # IP 대역 확인
                if ip.startswith("10.") or ip.startswith("172.") or ip.startswith("192.168."):
                    print(f"    ✓ Private IP detected - Using private connection")
                elif ip.startswith("199.36.153.") or ip.startswith("199.36.154."):
                    print(f"    ✓ Google Private Access IP range - Using private connection")
                else:
                    print(f"    ⚠️  Public IP - May be using public internet")
                    
        except socket.gaierror as e:
            print(f"\n{endpoint}: DNS resolution failed - {e}")

def check_routing_table():
    """라우팅 테이블 확인"""
    print("\n\n2. Routing Table Check")
    print("=" * 60)
    
    # 주요 Google API 대역 확인
    google_ranges = [
        "199.36.153.0/24",  # Google Private Access
        "199.36.154.0/23",  # Google Private Access
        "10.0.0.0/8",       # Private IP range
        "172.16.0.0/12",    # Private IP range
    ]
    
    print("\nCurrent routing table:")
    stdout, stderr, _ = run_command("ip route show")
    if stdout:
        print(stdout)
    
    print("\n\nRoutes to Google API endpoints:")
    
    # 특정 엔드포인트로의 라우팅 확인
    try:
        api_ip = socket.gethostbyname("aiplatform.googleapis.com")
        stdout, stderr, _ = run_command(f"ip route get {api_ip}")
        if stdout:
            print(f"\nRoute to aiplatform.googleapis.com ({api_ip}):")
            print(stdout)
            
            # VPN/Interconnect 인터페이스 확인
            if "tun" in stdout or "vpn" in stdout or "vti" in stdout:
                print("✓ Traffic appears to be routed through VPN tunnel")
            elif "eth" in stdout and "via" in stdout:
                # Gateway IP 확인
                if "via 10." in stdout or "via 172." in stdout or "via 192.168." in stdout:
                    print("✓ Traffic routed through private gateway")
                else:
                    print("⚠️  Traffic may be routed through public internet")
    except:
        pass

def check_network_interfaces():
    """네트워크 인터페이스 확인"""
    print("\n\n3. Network Interface Check")
    print("=" * 60)
    
    stdout, stderr, _ = run_command("ip addr show")
    if stdout:
        lines = stdout.split('\n')
        current_interface = None
        
        for line in lines:
            if ': ' in line and not line.startswith(' '):
                # 인터페이스 이름 추출
                parts = line.split(': ')
                if len(parts) >= 2:
                    current_interface = parts[1].split('@')[0]
                    
            if current_interface and ('tun' in current_interface or 'vpn' in current_interface or 'vti' in current_interface):
                print(f"\n✓ VPN Interface detected: {current_interface}")
                if 'inet ' in line:
                    print(f"  {line.strip()}")

def check_vpn_status():
    """VPN 연결 상태 확인"""
    print("\n\n4. VPN Connection Status")
    print("=" * 60)
    
    # IPSec 상태 확인
    print("\nChecking IPSec status:")
    stdout, stderr, _ = run_command("sudo ipsec status")
    if stdout and "ESTABLISHED" in stdout:
        print("✓ IPSec connection is ESTABLISHED")
    elif stderr and "command not found" not in stderr:
        print("⚠️  IPSec not configured or not running")
    
    # OpenVPN 상태 확인
    stdout, stderr, _ = run_command("sudo systemctl status openvpn")
    if stdout and "active (running)" in stdout:
        print("✓ OpenVPN is running")
    
    # WireGuard 상태 확인
    stdout, stderr, _ = run_command("sudo wg show")
    if stdout and "interface:" in stdout:
        print("✓ WireGuard is configured")

def trace_route_to_api():
    """API 엔드포인트까지의 경로 추적"""
    print("\n\n5. Traceroute to API Endpoints")
    print("=" * 60)
    
    try:
        api_ip = socket.gethostbyname("aiplatform.googleapis.com")
        print(f"\nTracing route to aiplatform.googleapis.com ({api_ip}):")
        
        # traceroute 실행 (첫 10 홉만)
        stdout, stderr, _ = run_command(f"traceroute -n -m 10 {api_ip}")
        if stdout:
            lines = stdout.split('\n')
            private_hops = 0
            total_hops = 0
            
            for line in lines[1:]:  # 첫 줄은 헤더
                if line.strip() and not line.startswith('traceroute'):
                    print(line)
                    total_hops += 1
                    
                    # Private IP 확인
                    if "10." in line or "172." in line or "192.168." in line:
                        private_hops += 1
            
            if private_hops > 0:
                print(f"\n✓ Found {private_hops} private IP hops out of {total_hops} total hops")
                print("  This indicates traffic is using private network path")
            else:
                print(f"\n⚠️  No private IP hops detected in {total_hops} hops")
                print("  Traffic may be using public internet")
                
    except Exception as e:
        print(f"Traceroute failed: {e}")

def check_firewall_rules():
    """방화벽 규칙 확인"""
    print("\n\n6. Firewall Rules Check")
    print("=" * 60)
    
    # iptables 규칙 확인
    print("\nChecking iptables rules for Google API traffic:")
    stdout, stderr, _ = run_command("sudo iptables -L -n -v | grep -E '(199.36.153|199.36.154|443)'")
    if stdout:
        print(stdout)
    else:
        print("No specific rules found for Google API traffic")

def check_private_google_access():
    """Private Google Access 설정 확인"""
    print("\n\n7. Private Google Access Configuration")
    print("=" * 60)
    
    print("\nChecking /etc/hosts for private endpoints:")
    stdout, stderr, _ = run_command("grep googleapis.com /etc/hosts")
    if stdout:
        print(stdout)
        print("✓ Custom DNS entries found for Google APIs")
    else:
        print("No custom DNS entries in /etc/hosts")
    
    print("\nChecking resolv.conf:")
    stdout, stderr, _ = run_command("cat /etc/resolv.conf | grep -E '(nameserver|search)'")
    if stdout:
        print(stdout)

def test_actual_connection():
    """실제 API 연결 테스트"""
    print("\n\n8. Actual API Connection Test")
    print("=" * 60)
    
    # curl을 사용한 연결 테스트
    print("\nTesting connection to Vertex AI endpoint:")
    
    # 헤더 정보 확인
    stdout, stderr, _ = run_command(
        "curl -I -s -X GET https://us-central1-aiplatform.googleapis.com/v1/projects"
    )
    
    if stdout:
        print("Response headers:")
        for line in stdout.split('\n')[:5]:  # 처음 5줄만
            print(f"  {line}")
    
    # 연결 정보 상세 확인
    print("\nConnection details:")
    stdout, stderr, _ = run_command(
        "curl -v -s -o /dev/null https://us-central1-aiplatform.googleapis.com 2>&1 | grep -E '(Connected to|subject:|issuer:)'"
    )
    if stdout:
        print(stdout)

def generate_summary():
    """검증 결과 요약"""
    print("\n\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)
    
    print("""
To verify if Gemini API calls are using private connection:

1. Check DNS Resolution:
   - Private IPs (10.x, 172.x, 192.168.x) = Private connection
   - Google Private Access IPs (199.36.153.x, 199.36.154.x) = Private connection
   - Other public IPs = May use public internet

2. Check Routing:
   - Routes through VPN/tunnel interfaces = Private connection
   - Routes through private gateways = Private connection
   - Default route to public gateway = Public internet

3. Check VPN Status:
   - Active VPN/IPSec/WireGuard connection required for private access

4. Traceroute Analysis:
   - Private IP hops indicate private network path
   - All public IP hops indicate public internet path

5. Monitor Traffic:
   - Use tcpdump/wireshark to capture actual traffic
   - Check if traffic goes through VPN interface

Additional Commands to Run:
- sudo tcpdump -i any -n host aiplatform.googleapis.com
- ss -tunp | grep :443
- netstat -rn
""")

def main():
    """메인 실행 함수"""
    print("=" * 60)
    print("Gemini API Private Connection Verification")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # 각 검증 단계 실행
    check_dns_resolution()
    check_routing_table()
    check_network_interfaces()
    check_vpn_status()
    trace_route_to_api()
    check_firewall_rules()
    check_private_google_access()
    test_actual_connection()
    generate_summary()
    
    print("\n✅ Verification complete!")
    print("\nFor real-time traffic monitoring, run:")
    print("sudo tcpdump -i any -n -s0 -w gemini_traffic.pcap host aiplatform.googleapis.com")
    print("\nThen analyze the pcap file to see the actual network path.")

if __name__ == "__main__":
    main()