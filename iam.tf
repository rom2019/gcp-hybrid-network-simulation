# iam.tf - IAM roles and permissions

# Service account for Dev VM
# (Already defined in compute.tf, just referencing here for clarity)

# Enable Cloud IAP for SSH access
resource "google_project_iam_member" "iap_ssh_user" {
  project = google_project.dev_project.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:${var.user_email}"  # You'll need to define this variable
}

# Compute Instance Admin for the user (to SSH via IAP)
resource "google_project_iam_member" "compute_instance_admin" {
  project = google_project.dev_project.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "user:${var.user_email}"
}

# Service Account User permission (required for SSH via IAP)
resource "google_project_iam_member" "service_account_user" {
  project = google_project.dev_project.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "user:${var.user_email}"
}

# Gemini API custom role (optional)
resource "google_project_iam_custom_role" "gemini_user" {
  role_id     = "geminiApiUser"
  title       = "Gemini API User"
  description = "Custom role for using Gemini API with minimal permissions"
  project     = google_project.prod_project.project_id
  
  permissions = [
    "aiplatform.endpoints.predict",
    "aiplatform.models.get",
    "aiplatform.models.list",
    "aiplatform.locations.get",
    "aiplatform.locations.list",
    "resourcemanager.projects.get",
  ]
}

# Prod project IAM binding for AI Platform
resource "google_project_iam_binding" "prod_ai_users" {
  project = google_project.prod_project.project_id
  role    = "roles/aiplatform.user"
  
  members = [
    "serviceAccount:${google_service_account.dev_vm_sa.email}",
  ]
}

# Terraform service account (optional)
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
  project      = google_project.dev_project.project_id
}

# Terraform SA roles for Dev project
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

# Terraform SA roles for Prod project
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

# Logging roles
resource "google_project_iam_member" "logging_roles" {
  for_each = toset([
    google_project.dev_project.project_id,
    google_project.prod_project.project_id,
  ])
  
  project = each.key
  role    = "roles/logging.admin"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# VPN admin roles
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

# Audit logging for Gemini API
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

# Private Google Access DNS configuration
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