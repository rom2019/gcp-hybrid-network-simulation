# Access Context Manager API 오류 해결 가이드

## 문제 설명
Access Context Manager API 사용 시 다음과 같은 오류가 발생했습니다:
- `SERVICE_DISABLED`: accesscontextmanager.googleapis.com API가 비활성화됨
- 로컬 Application Default Credentials 사용 시 quota project 설정 필요

## 해결 방법

### 1. 수행한 변경사항

#### main.tf 수정
- Access Context Manager API를 항상 활성화하도록 변경
- 조직 레벨 작업을 위한 별도의 provider alias 추가

#### vpc_service_controls.tf 수정
- 모든 Access Context Manager 리소스에 `provider = google.org_level` 추가
- 조직 레벨에서 리소스가 생성되도록 설정

### 2. 인증 설정

#### 옵션 1: gcloud 인증 (권장)
```bash
# 1. gcloud로 로그인
gcloud auth login

# 2. Application Default Credentials 설정
gcloud auth application-default login

# 3. 기본 프로젝트 설정 (quota project로 사용됨)
gcloud config set project YOUR_PROJECT_ID
```

#### 옵션 2: 서비스 계정 사용
```bash
# 1. 서비스 계정 키 파일 생성
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# 2. 필요한 권한 부여
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/accesscontextmanager.policyAdmin"

# 3. 키 파일 생성
gcloud iam service-accounts keys create ~/terraform-key.json \
    --iam-account=terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. 환경 변수 설정
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
```

### 3. Terraform 실행

```bash
# 1. 초기화
terraform init -upgrade

# 2. 계획 확인
terraform plan

# 3. 적용
terraform apply
```

### 4. VPC Service Controls 활성화

VPC Service Controls를 사용하려면 terraform.tfvars에서 다음 설정을 추가하세요:

```hcl
enable_vpc_service_controls = true
organization_id = "YOUR_ORGANIZATION_ID"
```

## 주의사항

1. Access Context Manager는 조직 레벨에서 작동하므로 조직 ID가 필요합니다
2. 사용자 계정 또는 서비스 계정에 `roles/accesscontextmanager.policyAdmin` 권한이 필요합니다
3. VPC Service Controls는 Enterprise 기능이므로 적절한 라이선스가 필요할 수 있습니다

## 문제가 지속될 경우

1. API 활성화 확인:
```bash
gcloud services list --enabled | grep accesscontextmanager
```

2. 권한 확인:
```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.role:roles/accesscontextmanager.policyAdmin"
```

3. 조직 정책 확인:
```bash
gcloud resource-manager org-policies list --organization=YOUR_ORG_ID