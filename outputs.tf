# outputs.tf - Terraform 출력 값

# 프로젝트 정보
output "dev_project_id" {
  description = "Dev 프로젝트 ID"
  value       = google_project.dev_project.project_id
}

output "prod_project_id" {
  description = "Prod 프로젝트 ID"
  value       = google_project.prod_project.project_id
}

# 네트워크 정보
output "dev_vpc_name" {
  description = "Dev VPC 이름"
  value       = google_compute_network.dev_vpc.name
}

output "prod_vpc_name" {
  description = "Prod VPC 이름"
  value       = google_compute_network.prod_vpc.name
}

output "dev_subnet_cidr" {
  description = "Dev 서브넷 CIDR"
  value       = google_compute_subnetwork.dev_subnet.ip_cidr_range
}

output "prod_subnet_cidr" {
  description = "Prod 서브넷 CIDR"
  value       = google_compute_subnetwork.prod_subnet.ip_cidr_range
}

# VPN 정보
output "dev_vpn_gateway_ip" {
  description = "Dev VPN Gateway IP"
  value       = google_compute_ha_vpn_gateway.dev_gateway.vpn_interfaces[0].interconnect_attachment
}

output "prod_vpn_gateway_ip" {
  description = "Prod VPN Gateway IP"
  value       = google_compute_ha_vpn_gateway.prod_gateway.vpn_interfaces[0].interconnect_attachment
}

# VM 정보
output "dev_vm_name" {
  description = "Dev VM 이름"
  value       = google_compute_instance.dev_workstation.name
}

output "dev_vm_internal_ip" {
  description = "Dev VM 내부 IP"
  value       = google_compute_instance.dev_workstation.network_interface[0].network_ip
}

output "dev_vm_external_ip" {
  description = "Dev VM 외부 IP"
  value       = google_compute_instance.dev_workstation.network_interface[0].access_config[0].nat_ip
}

# 서비스 계정 정보
output "dev_vm_service_account" {
  description = "Dev VM 서비스 계정 이메일"
  value       = google_service_account.dev_vm_sa.email
}

# SSH 접속 명령어
output "ssh_command" {
  description = "Dev VM SSH 접속 명령어"
  value       = "gcloud compute ssh ${google_compute_instance.dev_workstation.name} --zone=${var.zone} --project=${google_project.dev_project.project_id}"
}

# VPN 상태 확인 명령어
output "check_vpn_status_dev" {
  description = "Dev VPN 상태 확인 명령어"
  value       = "gcloud compute vpn-tunnels describe dev-to-prod-tunnel1 --region=${var.region} --project=${google_project.dev_project.project_id}"
}

output "check_vpn_status_prod" {
  description = "Prod VPN 상태 확인 명령어"
  value       = "gcloud compute vpn-tunnels describe prod-to-dev-tunnel1 --region=${var.region} --project=${google_project.prod_project.project_id}"
}

# Gemini API 테스트 정보
output "gemini_test_instructions" {
  description = "Gemini API 테스트 방법"
  value = <<-EOT
    1. SSH로 Dev VM에 접속:
       ${google_compute_instance.dev_workstation.name}
    
    2. 테스트 스크립트 실행:
       python3 /home/debian/test_gemini.py
    
    3. 또는 직접 API 호출:
       curl -X POST \
         -H "Authorization: Bearer $(gcloud auth print-access-token)" \
         -H "Content-Type: application/json" \
         -d '{"contents":[{"parts":[{"text":"Hello from simulated on-prem!"}]}]}' \
         "https://us-central1-aiplatform.googleapis.com/v1/projects/${google_project.prod_project.project_id}/locations/us-central1/publishers/google/models/gemini-pro:generateContent"
  EOT
}

# VPC Service Controls 정보 (활성화된 경우)
output "vpc_service_controls_enabled" {
  description = "VPC Service Controls 활성화 여부"
  value       = var.enable_vpc_service_controls
}

output "service_perimeter_name" {
  description = "Service Perimeter 이름"
  value       = var.enable_vpc_service_controls && var.organization_id != "" ? google_access_context_manager_service_perimeter.gemini_perimeter[0].name : "Not enabled"
}

# 중요 참고사항
output "important_notes" {
  description = "중요 참고사항"
  value = <<-EOT
    ⚠️  중요 참고사항:
    
    1. VPN 연결 확인:
       - 양쪽 터널이 모두 'ESTABLISHED' 상태여야 합니다
       - BGP 세션이 활성화되어 있어야 합니다
    
    2. 비용 관리:
       - VPN은 시간당 과금됩니다
       - 사용하지 않을 때는 terraform destroy로 리소스를 삭제하세요
    
    3. 보안:
       - SSH 접근은 특정 IP로 제한하는 것을 권장합니다
       - VPN 공유 비밀키는 안전하게 관리하세요
    
    4. 테스트 후 정리:
       terraform destroy -auto-approve
  EOT
}