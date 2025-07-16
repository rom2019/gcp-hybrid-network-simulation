# Google Cloud Hybrid Network Architecture
## On-Premises Simulation with Gemini API Access

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    Google Cloud Platform                                         │
│                                                                                                  │
│  ┌─────────────────────────────────────┐         ┌─────────────────────────────────────┐       │
│  │   Dev Project (On-Prem Simulation)  │         │    Prod Project (Gemini API)       │       │
│  │   ID: on-prem-sim-[random]          │         │    ID: gemini-api-prod-[random]    │       │
│  │                                     │         │                                     │       │
│  │  ┌─────────────────────────────┐   │         │   ┌─────────────────────────────┐  │       │
│  │  │    Dev VPC (10.0.0.0/16)    │   │         │   │   Prod VPC (10.1.0.0/16)   │  │       │
│  │  │                             │   │         │   │                             │  │       │
│  │  │  ┌───────────────────────┐  │   │         │   │  ┌───────────────────────┐  │  │       │
│  │  │  │ Dev Subnet            │  │   │         │   │  │ Prod Subnet           │  │  │       │
│  │  │  │ (10.0.1.0/24)         │  │   │         │   │  │ (10.1.1.0/24)         │  │  │       │
│  │  │  │                       │  │   │         │   │  │                       │  │  │       │
│  │  │  │ ┌─────────────────┐  │  │   │         │   │  │ ┌─────────────────┐  │  │  │       │
│  │  │  │ │ Dev Workstation │  │  │   │         │   │  │ │ Prod Test VM    │  │  │  │       │
│  │  │  │ │ e2-medium       │  │  │   │         │   │  │ │ e2-micro        │  │  │  │       │
│  │  │  │ │ Debian 11       │  │  │   │         │   │  │ │ Debian 11       │  │  │  │       │
│  │  │  │ │ No External IP  │  │  │   │         │   │  │ │ Internal Only   │  │  │  │       │
│  │  │  │ └─────────────────┘  │  │   │         │   │  │ └─────────────────┘  │  │  │       │
│  │  │  │                       │  │   │         │   │  │                       │  │  │       │
│  │  │  │ ┌─────────────────┐  │  │   │         │   │  │ ┌─────────────────┐  │  │  │       │
│  │  │  │ │   Cloud NAT     │  │  │   │         │   │  │ │   Cloud NAT     │  │  │  │       │
│  │  │  │ │   dev-nat       │  │  │   │         │   │  │ │   prod-nat      │  │  │  │       │
│  │  │  │ └─────────────────┘  │  │   │         │   │  │ └─────────────────┘  │  │  │       │
│  │  │  └───────────────────────┘  │   │         │   │  └───────────────────────┘  │  │       │
│  │  │                             │   │         │   │                             │  │       │
│  │  │      [HA VPN Gateway]       │   │         │   │      [HA VPN Gateway]      │  │       │
│  │  └─────────────┬───────────────┘   │         │   └──────────────┬─────────────┘  │       │
│  └────────────────┼────────────────────┘         └─────────────────┼─────────────────┘       │
│                   │                                                 │                         │
│                   │        HA VPN Tunnels (x2)                     │                         │
│                   └─────────────────────────────────────────────────┘                         │
│                            BGP Sessions (ASN: 64512 ↔ 64513)                                 │
│                                  IPsec Encrypted                                             │
│                                                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────┘

                                            │
                                            │ API Access
                                            ▼
                        
┌─────────────────────────────────────────────────────────────────────┐
│                     Google APIs & Services                          │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐   │
│  │      Gemini API         │    │   Private Google Access     │   │
│  │   (Vertex AI)           │    │                             │   │
│  │   us-central1           │    │   Cloud DNS                 │   │
│  │   gemini-pro            │    │   restricted.googleapis.com │   │
│  └─────────────────────────┘    │   199.36.153.8-11           │   │
│                                  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│      Cloud IAP          │
│   SSH Access            │
│   35.235.240.0/20       │
│   No External IP needed │
└───────────┬─────────────┘
            │
            └────────────► Dev Workstation
```

## 주요 구성 요소

### 1. **프로젝트 구조**
- **Dev Project (On-Premises Simulation)**
  - Project ID: `on-prem-sim-[random]`
  - 온프레미스 환경을 시뮬레이션
  - 개발자 워크스테이션 호스팅

- **Prod Project (Gemini API)**
  - Project ID: `gemini-api-prod-[random]`
  - Gemini API 접근을 위한 프로덕션 환경
  - 보안 강화된 환경

### 2. **네트워크 구성**
- **Dev VPC**: `10.0.0.0/16`
  - Dev Subnet: `10.0.1.0/24`
  - Private Google Access 활성화
  - Cloud NAT 구성 (인터넷 아웃바운드)

- **Prod VPC**: `10.1.0.0/16`
  - Prod Subnet: `10.1.1.0/24`
  - Private Google Access 활성화
  - Cloud NAT 구성

### 3. **VPN 연결**
- **HA VPN Gateways**: 양쪽 VPC에 고가용성 VPN 게이트웨이
- **VPN Tunnels**: 이중화를 위한 2개의 터널
- **BGP Sessions**: 
  - Dev ASN: 64512
  - Prod ASN: 64513
  - 동적 라우팅을 위한 BGP 구성
- **IPsec 암호화**: 모든 트래픽 암호화

### 4. **컴퓨트 리소스**
- **Dev Workstation**
  - Machine Type: `e2-medium`
  - OS: Debian 11
  - External IP 없음 (Cloud IAP 통한 SSH)
  - Service Account: `dev-vm-sa`

- **Prod Test VM**
  - Machine Type: `e2-micro`
  - OS: Debian 11
  - 내부 전용 (External IP 없음)

### 5. **보안 구성**

#### Firewall Rules
- **Dev VPC**:
  - ✅ Cloud IAP SSH 허용 (35.235.240.0/20)
  - ✅ 내부 통신 허용
  - ✅ VPN 트래픽 허용
  - ✅ Health Check 허용

- **Prod VPC**:
  - ✅ VPN 트래픽 허용
  - ✅ 내부 통신 허용
  - ❌ SSH 차단 (보안 강화)
  - ✅ HTTPS (443) Dev 네트워크에서만 허용

#### IAM 구성
- **Service Account**: `dev-vm-sa`
  - Dev Project: `roles/aiplatform.user`
  - Prod Project: `roles/aiplatform.user` (Cross-project access)
  - Logging/Monitoring 권한

- **User Access**:
  - `roles/iap.tunnelResourceAccessor` (IAP SSH)
  - `roles/compute.instanceAdmin.v1`
  - `roles/iam.serviceAccountUser`

### 6. **Google API 접근**
- **Private Google Access**: 활성화
- **Cloud DNS**: 
  - Private zone for `googleapis.com`
  - `restricted.googleapis.com` → `199.36.153.8-11`
- **Gemini API**:
  - Vertex AI 통한 접근
  - Region: `us-central1`
  - Model: `gemini-pro`

### 7. **관리 도구**
- **Cloud IAP**: External IP 없이 안전한 SSH 접근
- **Cloud NAT**: 아웃바운드 인터넷 연결
- **Cloud Logging**: 모든 활동 로깅
- **Audit Logging**: Gemini API 사용 감사

## 데이터 흐름

1. **SSH 접근**: User → Cloud IAP → Dev Workstation
2. **Gemini API 호출**: 
   - Dev Workstation → Dev VPC → VPN → Prod VPC → Private Google Access → Gemini API
3. **인터넷 접근**: VM → Cloud NAT → Internet

## 주요 특징

- 🔒 **보안**: External IP 없이 Cloud IAP 통한 안전한 접근
- 🔄 **고가용성**: HA VPN with dual tunnels
- 🌐 **Private Access**: Google API에 대한 프라이빗 접근
- 📊 **모니터링**: 포괄적인 로깅 및 감사
- 🔐 **격리**: 프로젝트 간 격리 및 최소 권한 원칙