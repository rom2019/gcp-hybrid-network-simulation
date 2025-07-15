#!/bin/bash
# quick_start.sh - GCP Hybrid Network 빠른 시작 스크립트

set -e

echo "=== GCP Hybrid Network Simulation - Quick Start ==="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. 사전 요구사항 확인
echo -e "${BLUE}1. Checking prerequisites...${NC}"

# gcloud 확인
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗ gcloud CLI not found. Please install Google Cloud SDK.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ gcloud CLI found${NC}"

# terraform 확인
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found. Please install Terraform.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Terraform found ($(terraform version -json | jq -r .terraform_version))${NC}"

# 2. gcloud 인증 확인
echo -e "\n${BLUE}2. Checking authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}No active gcloud authentication found.${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated as: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')${NC}"

# 3. terraform.tfvars 파일 확인
echo -e "\n${BLUE}3. Checking configuration...${NC}"
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars not found. Creating from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${RED}Please edit terraform.tfvars with your actual values:${NC}"
    echo "  - billing_account_id"
    echo "  - vpn_shared_secret"
    echo "  - organization_id (if using VPC Service Controls)"
    exit 1
fi
echo -e "${GREEN}✓ terraform.tfvars found${NC}"

# 4. Terraform 초기화
echo -e "\n${BLUE}4. Initializing Terraform...${NC}"
terraform init

# 5. 계획 확인
echo -e "\n${BLUE}5. Creating Terraform plan...${NC}"
terraform plan -out=tfplan

# 6. 사용자 확인
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}IMPORTANT: This will create the following resources:${NC}"
echo "  - 2 GCP Projects"
echo "  - 2 VPC Networks with subnets"
echo "  - HA VPN Gateways and tunnels"
echo "  - 1 Compute Instance (Dev Workstation)"
echo "  - Firewall rules and IAM configurations"
echo ""
echo -e "${YELLOW}Estimated monthly cost: ~$50-100 (depending on usage)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
read -p "Do you want to proceed? (yes/no): " -n 3 -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# 7. Terraform 적용
echo -e "\n${BLUE}6. Applying Terraform configuration...${NC}"
terraform apply tfplan

# 8. 출력 정보 저장
echo -e "\n${BLUE}7. Saving output information...${NC}"
terraform output -json > deployment_info.json
echo -e "${GREEN}✓ Deployment information saved to deployment_info.json${NC}"

# 9. 연결 정보 표시
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "1. Wait 2-3 minutes for VPN tunnels to establish"
echo "2. SSH to Dev VM:"
echo -e "   ${BLUE}$(terraform output -raw ssh_command)${NC}"
echo ""
echo "3. Test connectivity:"
echo "   chmod +x /home/debian/test_connectivity.sh"
echo "   ./test_connectivity.sh"
echo ""
echo "4. Test Gemini API:"
echo "   python3 /home/debian/test_gemini.py"
echo ""
echo -e "${YELLOW}Remember to destroy resources when done:${NC}"
echo -e "   ${BLUE}terraform destroy${NC}"
echo ""