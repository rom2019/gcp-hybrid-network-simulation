# variables.tf - Terraform 변수 정의

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
}


variable "region" {
  description = "기본 리전"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "기본 존"
  type        = string
  default     = "us-central1-a"
}

variable "dev_project_id" {
  description = "Dev (On-premises simulation) 프로젝트 ID"
  type        = string
  default     = "on-prem-sim"
}

variable "prod_project_id" {
  description = "Production (Gemini API) 프로젝트 ID"
  type        = string
  default     = "gemini-api-prod"
}

variable "dev_vpc_cidr" {
  description = "Dev VPC CIDR 범위"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dev_subnet_cidr" {
  description = "Dev Subnet CIDR 범위"
  type        = string
  default     = "10.0.1.0/24"
}

variable "prod_vpc_cidr" {
  description = "Prod VPC CIDR 범위"
  type        = string
  default     = "10.1.0.0/16"
}

variable "prod_subnet_cidr" {
  description = "Prod Subnet CIDR 범위"
  type        = string
  default     = "10.1.1.0/24"
}

variable "vpn_shared_secret" {
  description = "VPN 공유 비밀키"
  type        = string
  sensitive   = true
}

variable "dev_vm_machine_type" {
  description = "Dev VM 머신 타입"
  type        = string
  default     = "e2-medium"
}


variable "allowed_ssh_source_ranges" {
  description = "SSH 접속을 허용할 소스 IP 범위"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "project_labels" {
  description = "프로젝트에 적용할 라벨"
  type        = map(string)
  default = {
    environment = "simulation"
    purpose     = "gemini-api-test"
  }
}

variable "user_email" {
  description = "User email for IAP SSH access"
  type        = string
  default = "admin@romij.altostrat.com"
}

# New IAM User (Service Account) variables
variable "new_iam_user_id" {
  description = "Service Account ID for the new IAM user"
  type        = string
  default     = "my-service-account"
}

variable "new_iam_user_display_name" {
  description = "Display name for the new IAM user"
  type        = string
  default     = "My Service Account"
}

variable "new_iam_user_roles" {
  description = "List of roles to assign to the new IAM user in dev project"
  type        = list(string)
  default = [
    "roles/viewer",                    # Basic read access
    "roles/compute.instanceAdmin",     # Manage compute instances
    "roles/storage.objectViewer",      # Read storage objects
    "roles/logging.viewer",            # View logs
    "roles/monitoring.viewer"          # View monitoring data
  ]
}

variable "grant_prod_access" {
  description = "Whether to grant access to prod project"
  type        = bool
  default     = false
}

variable "new_iam_user_prod_roles" {
  description = "List of roles to assign to the new IAM user in prod project"
  type        = list(string)
  default = [
    "roles/viewer",                    # Basic read access
    "roles/aiplatform.user"           # Use AI Platform/Gemini API
  ]
}