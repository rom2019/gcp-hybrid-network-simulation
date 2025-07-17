#!/usr/bin/env python3
"""
test_gemini_api.py - Gemini API 테스트 스크립트
On-premises 시뮬레이션 환경에서 Gemini Code Assist API 접근 테스트
"""

import os
import sys
import json
import time
from datetime import datetime

try:
    import vertexai
    from vertexai.generative_models import GenerativeModel, ChatSession
    from google.auth import default
    from google.auth.transport.requests import Request
except ImportError as e:
    print(f"Error: Required libraries not installed. {e}")
    print("Please run: pip3 install google-cloud-aiplatform")
    sys.exit(1)

# 환경 변수에서 프로젝트 ID 가져오기 (또는 하드코딩)
PROD_PROJECT_ID = os.environ.get('PROD_PROJECT_ID', 'my-gemini-prod-088dfe15')
LOCATION = os.environ.get('LOCATION', 'us-central1')

def test_authentication():
    """인증 테스트"""
    print("1. Testing Authentication...")
    try:
        credentials, project = default()
        print(f"   ✓ Default credentials loaded")
        print(f"   ✓ Service account: {credentials.service_account_email if hasattr(credentials, 'service_account_email') else 'User credentials'}")
        
        # 토큰 새로고침
        credentials.refresh(Request())
        print(f"   ✓ Access token refreshed")
        return True
    except Exception as e:
        print(f"   ✗ Authentication failed: {e}")
        return False

def test_vertex_ai_init():
    """Vertex AI 초기화 테스트"""
    print("\n2. Initializing Vertex AI...")
    try:
        vertexai.init(project=PROD_PROJECT_ID, location=LOCATION)
        print(f"   ✓ Vertex AI initialized")
        print(f"   ✓ Project: {PROD_PROJECT_ID}")
        print(f"   ✓ Location: {LOCATION}")
        return True
    except Exception as e:
        print(f"   ✗ Vertex AI initialization failed: {e}")
        return False

def test_gemini_model():
    """Gemini 모델 접근 테스트"""
    print("\n3. Testing Gemini Model Access...")
    try:
        model = GenerativeModel("gemini-2.5-flash")
        print(f"   ✓ Gemini Pro model loaded")
        return model
    except Exception as e:
        print(f"   ✗ Failed to load Gemini model: {e}")
        return None

def test_simple_generation(model):
    """간단한 텍스트 생성 테스트"""
    print("\n4. Testing Simple Text Generation...")
    try:
        prompt = "Hello Gemini! Please respond with a simple greeting. This is a test from a simulated on-premises environment."
        
        print(f"   Prompt: {prompt}")
        start_time = time.time()
        
        response = model.generate_content(prompt)
        
        end_time = time.time()
        print(f"   ✓ Response received in {end_time - start_time:.2f} seconds")
        print(f"   Response: {response.text[:200]}...")
        return True
    except Exception as e:
        print(f"   ✗ Text generation failed: {e}")
        return False

def test_code_generation(model):
    """코드 생성 테스트 (Gemini Code Assist 시뮬레이션)"""
    print("\n5. Testing Code Generation (Code Assist Simulation)...")
    try:
        code_prompt = """
        Write a Python function that connects to a Cloud SQL database using SQLAlchemy.
        Include proper error handling and connection pooling.
        """
        
        print(f"   Code request: Generate Cloud SQL connection function")
        start_time = time.time()
        
        response = model.generate_content(code_prompt)
        
        end_time = time.time()
        print(f"   ✓ Code generated in {end_time - start_time:.2f} seconds")
        print(f"   Generated code preview:")
        print("   " + "-" * 50)
        # 처음 몇 줄만 출력
        lines = response.text.split('\n')[:10]
        for line in lines:
            print(f"   {line}")
        print("   " + "-" * 50)
        return True
    except Exception as e:
        print(f"   ✗ Code generation failed: {e}")
        return False

def test_chat_session(model):
    """채팅 세션 테스트"""
    print("\n6. Testing Chat Session (Multi-turn conversation)...")
    try:
        chat = model.start_chat(history=[])
        
        # 첫 번째 메시지
        response1 = chat.send_message("I'm connecting from a simulated on-premises environment through VPN. Can you confirm you received this?")
        print(f"   ✓ First message sent and received")
        
        # 두 번째 메시지
        response2 = chat.send_message("Great! Now, can you explain what VPC Service Controls are in GCP?")
        print(f"   ✓ Second message sent and received")
        print(f"   Chat response preview: {response2.text[:150]}...")
        
        return True
    except Exception as e:
        print(f"   ✗ Chat session failed: {e}")
        return False

def test_network_path():
    """네트워크 경로 정보 출력"""
    print("\n7. Network Path Information:")
    try:
        import socket
        import subprocess
        
        # 현재 호스트 정보
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        print(f"   Source hostname: {hostname}")
        print(f"   Source IP: {local_ip}")
        
        # API 엔드포인트 확인
        api_endpoint = f"{LOCATION}-aiplatform.googleapis.com"
        try:
            api_ip = socket.gethostbyname(api_endpoint)
            print(f"   API endpoint: {api_endpoint}")
            print(f"   API IP: {api_ip}")
        except:
            print(f"   API endpoint: {api_endpoint} (IP resolution failed)")
        
        # 라우팅 정보 (Linux only)
        if sys.platform.startswith('linux'):
            try:
                result = subprocess.run(['ip', 'route', 'get', api_ip], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    print(f"   Route to API: {result.stdout.strip()}")
            except:
                pass
                
    except Exception as e:
        print(f"   Network information unavailable: {e}")

def main():
    """메인 테스트 실행"""
    print("=" * 60)
    print("Gemini API Connectivity Test")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Target Project: {PROD_PROJECT_ID}")
    print(f"Location: {LOCATION}")
    print("=" * 60)
    
    # 테스트 실행
    results = {
        "authentication": False,
        "vertex_init": False,
        "model_load": False,
        "text_generation": False,
        "code_generation": False,
        "chat_session": False
    }
    
    # 1. 인증 테스트
    if test_authentication():
        results["authentication"] = True
        
        # 2. Vertex AI 초기화
        if test_vertex_ai_init():
            results["vertex_init"] = True
            
            # 3. 모델 로드
            model = test_gemini_model()
            if model:
                results["model_load"] = True
                
                # 4. 텍스트 생성
                if test_simple_generation(model):
                    results["text_generation"] = True
                
                # 5. 코드 생성
                if test_code_generation(model):
                    results["code_generation"] = True
                
                # 6. 채팅 세션
                if test_chat_session(model):
                    results["chat_session"] = True
    
    # 7. 네트워크 정보
    test_network_path()
    
    # 결과 요약
    print("\n" + "=" * 60)
    print("TEST SUMMARY:")
    print("=" * 60)
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{test_name.replace('_', ' ').title()}: {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n✅ All tests passed! Gemini API is accessible from the simulated on-premises environment.")
    else:
        print("\n⚠️  Some tests failed. Check the network connectivity and permissions.")
    
    print("\nTroubleshooting tips:")
    print("1. Verify VPN tunnel is established: gcloud compute vpn-tunnels list")
    print("2. Check IAM permissions: Ensure the service account has 'AI Platform User' role")
    print("3. Verify API is enabled: gcloud services list --enabled | grep aiplatform")
    print("4. Check VPC Service Controls if enabled")
    
    return 0 if passed == total else 1

if __name__ == "__main__":
    sys.exit(main())