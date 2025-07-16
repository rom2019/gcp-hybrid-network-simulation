# DNS Configuration Guide for Private Google API Access

이 문서는 온프레미스 시뮬레이션 환경에서 VPN을 통해 Google API에 비공개로 접근하기 위한 DNS 구성을 설명합니다.

## 개요

온프레미스 환경에서 `googleapis.com` 도메인에 접근할 때, 공용 인터넷이 아닌 VPN 터널을 통해 비공개로 접근하도록 DNS를 구성합니다.

## 아키텍처

```
[On-Prem VM] → DNS Query → [Dev VPC DNS] → Forward to → [Prod VPC DNS] 
                                                              ↓
                                                    [Private DNS Zone]
                                                              ↓
                                                    Returns Private IP
                                                    (199.36.153.8/30)
```

## 구성 요소

### 1. Prod VPC의 Private DNS Zone
- **목적**: `googleapis.com` 도메인을 `private.googleapis.com`의 비공개 IP로 해석
- **구성**:
  ```hcl
  resource "google_dns_managed_zone" "googleapis_private_zone" {
    name     = "googleapis-private-zone"
    dns_name = "googleapis.com."
    visibility = "private"
  }
  ```

### 2. DNS 레코드
- **A 레코드**: `private.googleapis.com` → `199.36.153.8-11`
- **CNAME 레코드**: `*.googleapis.com` → `private.googleapis.com`

### 3. DNS 정책
- **Prod VPC Inbound Policy**: 외부 VPC로부터 DNS 쿼리 수신 허용
- **Dev VPC Outbound Policy**: `googleapis.com` 쿼리를 Prod VPC로 전달

### 4. DNS Forwarding Zone (Dev VPC)
- **목적**: `googleapis.com` 도메인에 대한 쿼리를 Prod VPC의 DNS로 전달
- **대상**: Cloud DNS 포워더 IP 범위 (`35.199.192.0/19`)

## 작동 원리

1. **DNS 쿼리 시작**
   - Dev VM에서 `us-central1-aiplatform.googleapis.com` 조회
   
2. **DNS 전달**
   - Dev VPC의 DNS가 쿼리를 받음
   - Forwarding Zone 설정에 따라 Prod VPC의 DNS로 전달
   
3. **Private Zone 조회**
   - Prod VPC의 Private DNS Zone에서 조회
   - `*.googleapis.com` → `private.googleapis.com` CNAME 반환
   - `private.googleapis.com` → `199.36.153.x` A 레코드 반환
   
4. **비공개 IP 반환**
   - Dev VM은 `199.36.153.x` IP를 받음
   - 이 IP는 Google의 Private Service Connect 엔드포인트
   
5. **API 호출**
   - Dev VM이 반환된 비공개 IP로 HTTPS 요청
   - 트래픽은 VPN 터널을 통해 전달됨

## 테스트 방법

### 1. DNS 해석 테스트
```bash
# Dev VM에서 실행
nslookup us-central1-aiplatform.googleapis.com

# 예상 결과:
# Address: 199.36.153.8 (또는 .9, .10, .11)
```

### 2. 경로 추적
```bash
# Dev VM에서 실행
traceroute us-central1-aiplatform.googleapis.com

# 첫 번째 홉이 10.1.x.x (Prod VPC) 범위여야 함
```

### 3. API 호출 테스트
```bash
# Dev VM에서 실행
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/[PROJECT]/locations/us-central1/models
```

## 문제 해결

### DNS가 공개 IP를 반환하는 경우
1. DNS Forwarding Zone이 올바르게 구성되었는지 확인
2. Dev VPC의 DNS 정책이 활성화되었는지 확인
3. 방화벽 규칙이 DNS 트래픽(UDP/TCP 53)을 허용하는지 확인

### DNS 쿼리가 실패하는 경우
1. VPN 터널이 활성 상태인지 확인
2. Prod VPC의 Inbound DNS Policy가 활성화되었는지 확인
3. 네트워크 간 라우팅이 올바른지 확인

### API 호출이 실패하는 경우
1. 서비스 계정에 필요한 IAM 권한이 있는지 확인
2. Private Google Access가 Prod VPC에서 활성화되었는지 확인
3. 199.36.153.8/30 대역으로의 라우트가 존재하는지 확인

## 보안 고려사항

1. **트래픽 격리**: 모든 API 트래픽이 VPN 터널을 통해 전달됨
2. **DNS 보안**: DNS 쿼리도 VPN을 통해 안전하게 전달됨
3. **접근 제어**: IAM과 방화벽 규칙으로 접근 제어

## 비용 최적화

1. **DNS 쿼리**: Cloud DNS 쿼리는 백만 건당 $0.40
2. **VPN 터널**: 시간당 과금되므로 사용하지 않을 때는 삭제
3. **Private Service Connect**: 추가 비용 없음

## 참고 자료

- [Private Google Access](https://cloud.google.com/vpc/docs/private-google-access)
- [Cloud DNS Private Zones](https://cloud.google.com/dns/docs/zones#creating-private-zones)
- [DNS Forwarding](https://cloud.google.com/dns/docs/zones#creating-forwarding-zones)