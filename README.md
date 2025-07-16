# GCP Hybrid Network Simulation for Private API Access

이 프로젝트는 on-premises 환경을 시뮬레이션하여, Cloud VPN을 통해 Google Cloud의 서비스(예: Gemini API)에 **공용 인터넷을 거치지 않고 비공개로 안전하게 접근**하는 하이브리드 네트워크 환경을 구축하고 검증합니다.

이 과정을 통해 우리는 Google Cloud의 Private Google Access가 BGP와 연동하여 동작하는 핵심 원리를 발견하고 증명합니다.

## 최종 아키텍처

```mermaid
graph TB
    subgraph "Simulated On-Premises Environment"
        subgraph "Dev Project: on-prem-sim"
            A["Dev Workstation VM<br/>10.0.1.x"] --> B{"Dev VPC<br/>10.0.0.0/16"}
            B --> R1["Cloud Router - Dev<br/>ASN 64512"]
            R1 --> V1["HA VPN Gateway - Dev"]
            
            subgraph "DNS in Dev Project"
                DNS["Private DNS Zone<br/>googleapis.com -> 199.36.153.8/30"]
            end
            B -- "uses" --> DNS
        end
    end
    
    subgraph "Google Cloud Production"
        subgraph "Prod Project: gemini-api-prod"
            V2["HA VPN Gateway - Prod"] --> R2["Cloud Router - Prod<br/>ASN 64513"]
            R2 --> F{"Prod VPC<br/>10.1.0.0/16"}
            F -- "enables" --> PGA["Private Google Access"]
        end
    end
    
    subgraph "Google Services"
        API["Google APIs<br/>(Gemini, etc.)<br/>199.36.153.8/30"]
    end
    
    V1 <-.HA VPN Tunnel.-> V2
    
    R2 -- "Advertise Route<br/>199.36.153.8/30" --> R1
    A -.- "3. API Call via VPN" --> API
    
    A -- "1. DNS Query" --> DNS
    DNS -- "2. Return Private IP" --> A
    
    style A fill:#e1f5fe
    style API fill:#e3f2fd
    style R2 stroke:#ff5722,stroke-width:2px
```

## 핵심 동작 원리

이 아키텍처의 핵심은 **"BGP 경로 광고가 곧 접근 권한"**이라는 점입니다.

1.  **DNS 해석 (Dev VPC)**: Dev VM이 `aiplatform.googleapis.com`을 조회하면, Dev VPC 내의 **자체 비공개 DNS 영역**이 `199.36.153.x`와 같은 비공개 IP를 반환합니다.
2.  **경로 광고 (Prod VPC)**: Prod VPC의 Cloud Router가 BGP를 통해 **`199.36.153.8/30` 경로를 알고 있다고 VPN 터널 너머로 광고**합니다.
3.  **라우팅 (Dev VPC)**: Dev VPC의 Cloud Router는 이 광고를 수신하여, `199.36.153.x`로 가는 경로는 VPN 터널을 통과해야 한다는 것을 학습합니다.
4.  **API 호출**: Dev VM이 비공개 IP로 API를 호출하면, 학습된 경로에 따라 트래픽이 **VPN 터널을 통해 Google 네트워크로 안전하게 전달**됩니다.
5.  **접근 허가**: Google 네트워크 엣지는 신뢰할 수 있는 VPN 연결을 통해 들어온 트래픽이고, 해당 연결의 BGP 세션이 목적지 경로를 광고하고 있음을 확인하고, **API 접근을 최종적으로 허용**합니다.

**중요**: 실제 API 트래픽은 Prod VPC를 경유하지 않으며, Prod VPC의 역할은 오직 BGP 경로를 광고하여 Dev VPC에 경로 정보를 알려주고 접근을 허가하는 **"관문"** 역할에 있습니다.

## 설정 방법

1.  **변수 설정**: `terraform.tfvars.example` 파일을 `terraform.tfvars`로 복사하고, 실제 프로젝트 환경에 맞게 값을 수정합니다.
2.  **인프라 배포**:
    ```bash
    terraform init
    terraform apply
    ```

## 검증 방법

배포가 완료된 후, 다음 단계를 통해 아키텍처가 올바르게 작동하는지 검증할 수 있습니다.

### 1. Dev VM 접속
```bash
# [project-suffix]는 terraform output으로 확인
gcloud compute ssh dev-workstation --zone=us-central1-a --project=on-prem-sim-[project-suffix]
```

### 2. DNS 해석 확인
Dev VM에서 실행합니다. `199.36.153.x` 범위의 비공개 IP가 반환되어야 합니다.
```bash
nslookup aiplatform.googleapis.com
```

### 3. 네트워크 경로 확인 (가장 확실한 방법)
`tcpdump`와 `traceroute`를 함께 사용하여 트래픽이 비공개 경로로 가는지 확인합니다.

```bash
# Dev VM에서 실행
# 1. tcpdump 실행 (백그라운드)
sudo tcpdump -i any -n host aiplatform.googleapis.com &

# 2. API 호출 (트래픽 발생)
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" https://aiplatform.googleapis.com/

# 3. tcpdump 결과 확인: 목적지 IP가 199.36.153.x로 표시되어야 함

# 4. traceroute 실행
sudo traceroute -T -p 443 aiplatform.googleapis.com
# 결과: 중간에 공인 IP 없이, 몇 개의 * 뒤에 바로 목적지 IP(199.36.153.x)가 보여야 함
```

### 4. BGP 경로 광고의 중요성 검증 (심화)
`vpn.tf` 파일에서 `prod_vpn_router`의 `advertised_ip_ranges`에 있는 `199.36.153.8/30` 블록을 주석 처리하고 `terraform apply`를 실행하면, API 호출이 실패하는 것을 통해 BGP 경로 광고가 핵심임을 증명할 수 있습니다.

## 정리

인프라 사용이 끝나면 반드시 리소스를 삭제하여 비용이 발생하지 않도록 합니다.
```bash
terraform destroy