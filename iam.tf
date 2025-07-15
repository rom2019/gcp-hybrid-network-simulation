# iam.tf - IAM 역할 및 권한 설정

# Gemini API 사용을 위한 커스텀 역할 (선택사항)
resource "google_project_iam_custom_role" "gemini_user" {
  role_id     = "geminiApiUser"
  title       = "Gemini API User"
  description = "Custom role for using Gemini API with minimal permissions"
  project     = google_project.prod_project.project_id
  
  permissions = [
    "aiplatform.endpoints.predict",
    "aiplatform.models.predict",
    "aiplatform.locations.get",
    "aiplatform.locations.list",
    "resourcemanager.projects.get",
  ]
}

# Prod 프로젝트 기본 IAM 바인딩
resource "google_project_iam_binding" "prod_ai_users" {
  project = google_project.prod_project.project_id
  role    = "roles/aiplatform.user"
  
  members = [
    "serviceAccount:${google_service_account.dev_vm_sa.email}",
  ]
}

# VPC Service Controls를 위한 Access Context Manager Admin (조직 레벨)
resource "google_organization_iam_member" "access_context_admin" {
  count  = var.enable_vpc_service_controls && var.organization_id != "" ? 1 : 0
  org_id = var.organization_id
  role   = "roles/accesscontextmanager.policyAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Terraform 실행을 위한 서비스 계정 (선택사항)
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
  project      = google_project.dev_project.project_id
}

# Terraform SA에 필요한 역할들
resource "google_project_iam_member" "terraform_dev_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])
  
  project = google_project.dev_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_project_iam_member" "terraform_prod_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ])
  
  project = google_project.prod_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# 로깅 및 모니터링을 위한 역할
resource "google_project_iam_member" "logging_roles" {
  for_each = toset([
    google_project.dev_project.project_id,
    google_project.prod_project.project_id,
  ])
  
  project = each.key
  role    = "roles/logging.admin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# VPN 관리를 위한 역할
resource "google_project_iam_member" "vpn_admin_dev" {
  project = google_project.dev_project.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_project_iam_member" "vpn_admin_prod" {
  project = google_project.prod_project.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# 감사 로그 설정
resource "google_project_iam_audit_config" "prod_audit" {
  project = google_project.prod_project.project_id
  service = "aiplatform.googleapis.com"
  
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# 조직 정책 (선택사항 - Organization이 있는 경우)
resource "google_org_policy_policy" "restrict_vpn_peer_ips" {
  count  = var.organization_id != "" ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/compute.restrictVpnPeerIPs"
  parent = "organizations/${var.organization_id}"
  
  spec {
    rules {
      allow_all = "TRUE"
    }
  }
}

# Private Google Access를 위한 DNS 설정
resource "google_dns_managed_zone" "googleapis" {
  name        = "googleapis-zone"
  dns_name    = "googleapis.com."
  project     = google_project.dev_project.project_id
  description = "Private zone for Google APIs"
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.dev_vpc.id
    }
  }
}

resource "google_dns_record_set" "googleapis_a" {
  name         = "restricted.googleapis.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.googleapis.name
  project      = google_project.dev_project.project_id
  
  rrdatas = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11",
  ]
}

resource "google_dns_record_set" "googleapis_cname" {
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.googleapis.name
  project      = google_project.dev_project.project_id
  
  rrdatas = ["restricted.googleapis.com."]
}