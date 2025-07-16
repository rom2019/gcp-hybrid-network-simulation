# vpc_service_controls.tf - VPC Service Controls 설정 (선택사항)

# Access Context Manager Access Policy
resource "google_access_context_manager_access_policy" "policy" {
  count  = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  parent = "organizations/${var.organization_id}"
  title  = "Gemini API Security Policy"
}

# Access Level - Dev 네트워크에서만 접근 허용
resource "google_access_context_manager_access_level" "dev_network_access" {
  count  = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/accessLevels/dev_network_access"
  title  = "Dev Network Access Level"
  
  basic {
    conditions {
      # IP 기반 접근 제어
      ip_subnetworks = [var.dev_subnet_cidr]
      
      # 특정 서비스 계정만 허용
      members = [
        "serviceAccount:${google_service_account.dev_vm_sa.email}",
      ]
    }
  }
}

# Service Perimeter - Gemini API 보호
resource "google_access_context_manager_service_perimeter" "gemini_perimeter" {
  count  = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/servicePerimeters/gemini_perimeter"
  title  = "Gemini API Perimeter"
  
  # 일반 perimeter (dry-run 모드가 아님)
  status {
    # 보호할 프로젝트
    resources = [
      "projects/${google_project.prod_project.number}",
    ]
    
    # 제한할 서비스
    restricted_services = [
      "aiplatform.googleapis.com",
      "storage.googleapis.com",  # AI Platform이 사용하는 스토리지
    ]
    
    # 접근 레벨
    access_levels = [
      google_access_context_manager_access_level.dev_network_access[0].name,
    ]
    
    # VPC 접근 가능 서비스
    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = [
        "aiplatform.googleapis.com",
        "storage.googleapis.com",
      ]
    }
  }
  
  # Dry-run 모드로 먼저 테스트 (선택사항)
  # spec {
  #   resources = [
  #     "projects/${google_project.prod_project.number}",
  #   ]
  #   
  #   restricted_services = [
  #     "aiplatform.googleapis.com",
  #   ]
  #   
  #   access_levels = [
  #     google_access_context_manager_access_level.dev_network_access[0].name,
  #   ]
  # }
}

# Perimeter Bridge - 프로젝트 간 통신 허용 (필요시)
resource "google_access_context_manager_service_perimeter_resource" "bridge" {
  count          = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  perimeter_name = google_access_context_manager_service_perimeter.gemini_perimeter[0].name
  resource       = "projects/${google_project.dev_project.number}"
}

# Ingress Policy - Dev에서 Prod로의 접근 허용
resource "google_access_context_manager_service_perimeter_ingress_policy" "dev_to_prod" {
  count     = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  perimeter = google_access_context_manager_service_perimeter.gemini_perimeter[0].name
  
  ingress_from {
    identity_type = "ANY_SERVICE_ACCOUNT"
    sources {
      resource = "projects/${google_project.dev_project.number}"
    }
  }
  
  ingress_to {
    resources = ["*"]
    
    operations {
      service_name = "aiplatform.googleapis.com"
      
      method_selectors {
        method = "*"
      }
    }
  }
}

# Egress Policy - Prod에서 외부 리소스 접근 (필요시)
resource "google_access_context_manager_service_perimeter_egress_policy" "prod_egress" {
  count     = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  perimeter = google_access_context_manager_service_perimeter.gemini_perimeter[0].name
  
  egress_from {
    identity_type = "ANY_SERVICE_ACCOUNT"
  }
  
  egress_to {
    resources = ["*"]
    
    operations {
      service_name = "storage.googleapis.com"
      
      method_selectors {
        method = "*"
      }
    }
  }
}